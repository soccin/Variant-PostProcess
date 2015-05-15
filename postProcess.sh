#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
VARIANTSPIPEDIR=/home/socci/Code/Pipelines/CBE/Variant/variants_pipeline
BEDTOOLS=/opt/common/CentOS_6/bedtools/bedtools-2.22.0/bin/bedtools
VEPPATH=/opt/common/CentOS_6/vep/v79
GENOME=/common/data/assemblies/H.sapiens/hg19/hg19.fasta


if [ $# -ne 2 ]; then
	echo "usage: postProcess.sh PairingFile PipelineOutputDir"
	exit
fi

PAIRING=$1
PIPEOUT=$2
PIPEOUT=$(echo $PIPEOUT | sed 's/\/$//')

TDIR=_scratch
mkdir -p $TDIR

ln -s $GENOME $TDIR/$(basename $GENOME)

HAPLOTYPEVCF=$(ls $PIPEOUT/variants/haplotypecaller/*_HaplotypeCaller.vcf)
PROJECT=$(basename $HAPLOTYPEVCF | sed 's/_HaplotypeCaller.vcf//')
echo PROJECT=$PROJECT

#
# Get indels from Hapolotype caller
#

if [ ! -f "$TDIR/germline.maf2.vep" ]; then
    echo "Getting Germline MAF"
    $SDIR/getGermlineMaf.sh ${PROJECT} $HAPLOTYPEVCF $TDIR &
    GERMLINE_CPID=$!
fi

HAPMAF=${PROJECT}___qSomHC_InDels__TCGA_MAF.txt

if [ ! -f "$TDIR/$HAPMAF" ]; then
    $SDIR/vcf2maf0.py -c haplotypecaller -p $PAIRING -i $HAPLOTYPEVCF \
        -o $TDIR/hap_maf0
    $SDIR/pA_qSomHC.py <$TDIR/hap_maf0 >$TDIR/hap_maf1
    $SDIR/oldMAF2tcgaMAF.py hg19 $TDIR/hap_maf1 $TDIR/hap_maf2
    $SDIR/indelOnly.py <$TDIR/hap_maf2 >$TDIR/$HAPMAF
fi

echo "Done with haplotype processing ..."

#
# Get DMP re-filtered MAF from mutect
#

MUTECTDIR=$PIPEOUT/variants/mutect
echo $MUTECTDIR

if [ ! -f "$TDIR/merge_maf3" ]; then
    for vcf in $MUTECTDIR/*vcf; do
        BASE=$(basename $vcf | sed 's/.vcf//')
        normal=$(echo $vcf | perl -ne '/_(s_.*?)_(s_.*?)_mutect/; print "$1"')
        tumor=$(echo $vcf | perl -ne '/_(s_.*?)_(s_.*?)_mutect/; print "$2"')
        echo $vcf, $normal, $tumor
        $SDIR/vcf2maf0.py -c mutect -p $PAIRING \
            -t $tumor -n $normal -i $vcf \
            -o $TDIR/mt_maf0
        $SDIR/DMP_rescue.py  <$TDIR/mt_maf0 >$TDIR/mt_maf1
        $SDIR/oldMAF2tcgaMAF.py hg19 $TDIR/mt_maf1 $TDIR/mt_maf2
        awk -F"\t" '$40=="FILTER"||$40=="PASS"{print $0}' $TDIR/mt_maf2 \
            >$TDIR/${BASE}___DMPFilter_TCGA_MAF.txt
    done

    echo
    echo "Done with mutect rescue"
    echo


    #
    # merge_maf3 is a TCGA MAF
    #

    cat $TDIR/$HAPMAF | cut -f-39 >$TDIR/merge_maf3
    cat $TDIR/*___DMPFilter_TCGA_MAF.txt | egrep -v "^Hugo_Symbol" | cut -f-39 >>$TDIR/merge_maf3
fi

echo "Done with Mutect"

if [ ! -f "$TDIR/merge_maf3.vep" ]; then


/opt/common/CentOS_6/bin/v1/perl /opt/common/CentOS_6/vcf2maf/v1.5.2/maf2maf.pl \
    --vep-forks 12 \
	--tmp-dir /scratch/socci \
    --vep-path $VEPPATH \
	--vep-data $VEPPATH \
	--ref-fasta $TDIR/$(basename $GENOME) \
	--retain-cols Center,Verification_Status,Validation_Status,Mutation_Status,Sequencing_Phase,Sequence_Source,Validation_Method,Score,BAM_file,Sequencer,Tumor_Sample_UUID,Matched_Norm_Sample_UUID,Caller \
	--input-maf $TDIR/merge_maf3 \
	--output-maf $TDIR/merge_maf3.vep

$SDIR/maf2vcfSimple.sh $TDIR/merge_maf3.vep >$TDIR/merge_maf3.vcf
/home/socci/Code/Pipelines/Post/MAFFillOut/fillOutMAF_CBE.sh \
    $PIPEOUT/alignments $TDIR/merge_maf3.vcf $TDIR/fillOut.out &
FILLOUT_CPID=$!
fi

cat $TDIR/merge_maf3.vep \
    | egrep -v "(^#|^Hugo_Symbol)" \
    | awk '{print $5,$6-1,$7}' \
    | tr ' ' '\t'  >$TDIR/merge_maf3.bed

$BEDTOOLS slop -g ~/lib/bedtools/genomes/human.hg19.genome -b 1 -i $TDIR/merge_maf3.bed \
    | $BEDTOOLS getfasta -tab \
    -fi $GENOME -fo $TDIR/merge_maf3.seq -bed -

$BEDTOOLS intersect -a $TDIR/merge_maf3.bed \
    -b $SDIR/db/IMPACT_410_hg19_targets_plus3bp.bed -wa \
    | $BEDTOOLS sort -i - | awk '{print $1":"$2+1"-"$3}' | uniq >$TDIR/merge_maf3.impact410

$SDIR/mkTaylorMAF.py $TDIR/merge_maf3.seq $TDIR/merge_maf3.impact410 $TDIR/merge_maf3.vep \
    > ${PROJECT}___SOMATIC.vep.maf

echo "Waiting for GERMLINE "$GERMLINE_CPID
wait $GERMLINE_CPID
echo "DONE"
echo "Waiting for FILL "$FILLOUT_CPID
wait $FILLOUT_CPID
echo "DONE"