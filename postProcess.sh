#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ $# -ne 2 ]; then
	echo "usage: postProcess.sh PairingFile PipelineOutputDir"
	exit
fi

source $SDIR/paths.sh

PAIRING=$1
PIPEOUT=$2
PIPEOUT=$(echo $PIPEOUT | sed 's/\/$//')
PROJECT=$(echo $PIPEOUT | perl -ne 'm|/(Proj_[^/\s]*)|; print $1')
echo PROJECT=$PROJECT

BAM1=$(ls $PIPEOUT/alignments/*bam | head -1)
GENOME_BUILD=$($SDIR/getGenomeBuild.sh $BAM1)
echo BUILD=${GENOME_BUILD}

GENOME_SH=$SDIR/genomeInfo_${GENOME_BUILD}.sh
if [ ! -e "$GENOME_SH" ]; then
    echo "Unknown genome build ["${GENOME_BUILD}"]"
    exit
fi

echo "Loading genome [${GENOME_BUILD}]" $GENOME_SH
source $GENOME_SH
echo GENOME=$GENOME

TDIR=_scratch
mkdir -p $TDIR

ln -s $GENOME $TDIR/$(basename $GENOME)

HAPLOTYPEVCF=$(ls $PIPEOUT/variants/haplotypecaller/*_HaplotypeCaller.vcf)
LAYOUT=1
if [ ! -f "$HAPLOTYPEVCF" ]; then

    # New format output directories
    HAPLOTYPEVCF=$(ls $PIPEOUT/variants/snpsIndels/haplotypecaller/*_HaplotypeCaller.vcf)
    LAYOUT=2

    if [ -f "$HAPLOTYPEVCF" ]; then

        echo
        echo FATAL ERROR Can not find Haplotype file in directory
        echo $PIPEOUT/variants/haplotypecaller
        echo
        exit -1

    fi

fi

# Germline calls

if [ ! -f "$TDIR/germline_maf3.exac.vcf" ]; then
    bsub -o LSF/ -J GERM_${PROJECT} \
      -n 12 -We 59 -R "rusage[mem=32]" \
      $SDIR/getGermlineMaf.sh ${PROJECT} \
      $HAPLOTYPEVCF \
      $TDIR
fi


#
# Get indels from Hapolotype caller
#


HAPMAF=${PROJECT}___qSomHC_InDels__TCGA_MAF.txt

if [ ! -f "$TDIR/$HAPMAF" ]; then
    $SDIR/vcf2maf0.py -c haplotypecaller -p $PAIRING -i $HAPLOTYPEVCF \
        -o $TDIR/hap_maf0
    $SDIR/pA_qSomHC.py <$TDIR/hap_maf0 >$TDIR/hap_maf1
    $SDIR/oldMAF2tcgaMAF.py ${GENOME_BUILD} $TDIR/hap_maf1 $TDIR/hap_maf2
    $SDIR/indelOnly.py <$TDIR/hap_maf2 >$TDIR/hap_maf2b
    $SDIR/normalizeInDels.py $TDIR/hap_maf2b $TDIR/$HAPMAF
fi

echo $0 "Done with haplotype processing ..."

#
# Get DMP re-filtered MAF from mutect
#

if [ "$LAYOUT" == "1" ]; then
    MUTECTDIR=$PIPEOUT/variants/mutect
else
    MUTECTDIR=$PIPEOUT/variants/snpsIndels/mutect
fi

echo $0 $MUTECTDIR

if [ ! -f "$TDIR/merge_maf3" ]; then
    for vcf in $MUTECTDIR/*vcf; do
        BASE=$(basename $vcf | sed 's/.vcf//')
		PAIR=$($SDIR/getMutectPair.py $PAIRING $vcf)
		normal=$(echo $PAIR | perl -ne '/normal:=(\S+) tumor:=(\S+)$/; print $1')
		tumor=$(echo $PAIR | perl -ne '/normal:=(\S+) tumor:=(\S+)$/; print $2')
        echo $vcf, $normal, $tumor
        $SDIR/vcf2maf0.py -c mutect -p $PAIRING \
            -t $tumor -n $normal -i $vcf \
            -o $TDIR/mt_maf0
        $SDIR/DMP_rescue.py  <$TDIR/mt_maf0 >$TDIR/mt_maf1
        $SDIR/oldMAF2tcgaMAF.py ${GENOME_BUILD} $TDIR/mt_maf1 $TDIR/mt_maf2
        awk -F"\t" '$40=="FILTER"||$40=="PASS"{print $0}' $TDIR/mt_maf2 \
            >$TDIR/${BASE}___DMPFilter_TCGA_MAF.txt
    done

    echo
    echo $0 "Done with mutect rescue"
    echo


    #
    # merge_maf3 is a TCGA MAF
    #

    cat $TDIR/$HAPMAF | cut -f-39 >$TDIR/merge_maf3
    cat $TDIR/*___DMPFilter_TCGA_MAF.txt | egrep -v "^Hugo_Symbol" | cut -f-39 >>$TDIR/merge_maf3
fi

echo $0 "Done with Mutect"

if [ ! -f "$TDIR/merge_maf3.vep" ]; then

mkdir -p $TDIR/SOM
$PERL $VCF2MAF/maf2maf.pl \
    --vep-forks 12 \
    --tmp-dir $TDIR/SOM \
    --vep-path $VEPPATH \
	--vep-data $VEPPATH \
	--ref-fasta $TDIR/$(basename $GENOME) \
	--retain-cols Center,Verification_Status,Validation_Status,Mutation_Status,Sequencing_Phase,Sequence_Source,Validation_Method,Score,BAM_file,Sequencer,Tumor_Sample_UUID,Matched_Norm_Sample_UUID,Caller \
    --custom-enst $MSK_ISOFORMS \
	--input-maf $TDIR/merge_maf3 \
	--output-maf $TDIR/merge_maf3.vep


$SDIR/maf2vcfSimple.sh $GENOME_BUILD $TDIR/merge_maf3 >$TDIR/merge_maf3.vcf
cat $TDIR/merge_maf3.vcf | sed 's/^chr//' > $TDIR/maf3.vcf
$SDIR/bgzip $TDIR/maf3.vcf
$SDIR/tabix -p vcf $TDIR/maf3.vcf.gz
/opt/common/CentOS_6/bcftools/bcftools-1.2/bin/bcftools \
    annotate --annotations $EXACDB \
    --columns AC,AN,AF --output-type v --output $TDIR/maf3.exac.vcf $TDIR/maf3.vcf.gz

$SDIR/fillOutMAF_CBE.sh \
    $PIPEOUT/alignments $TDIR/merge_maf3.vcf $TDIR/fillOut.out &
FILLOUT_CPID=$!
fi

cat $TDIR/merge_maf3.vep \
    | egrep -v "(^#|^Hugo_Symbol)" \
    | awk '{print $5,$6-1,$7}' \
    | tr ' ' '\t'  >$TDIR/merge_maf3.bed

$BEDTOOLS slop -g $SDIR/db/human.${GENOME_BUILD}.genome -b 1 -i $TDIR/merge_maf3.bed \
    | $BEDTOOLS getfasta -tab \
    -fi $GENOME -fo $TDIR/merge_maf3.seq -bed -

$BEDTOOLS intersect -a $TDIR/merge_maf3.bed \
    -b $SDIR/db/IMPACT_410_${GENOME_BUILD}_targets_plus3bp.bed -wa \
    | $BEDTOOLS sort -i - | awk '{print $1":"$2+1"-"$3}' | uniq >$TDIR/merge_maf3.impact410

$SDIR/mkTaylorMAF.py $TDIR/merge_maf3.seq $TDIR/merge_maf3.impact410 $TDIR/maf3.exac.vcf $TDIR/merge_maf3.vep \
    > ${PROJECT}___SOMATIC.vep.maf

#echo $0 "Waiting for GERMLINE "$GERMLINE_CPID
#wait $GERMLINE_CPID
#echo $0 "DONE"
echo $0 "Waiting for FILL "$FILLOUT_CPID
wait $FILLOUT_CPID
echo $0 "DONE"

python2.7 $SDIR/zeng2MAFFill $TDIR/merge_maf3.vep $TDIR/fillOut.out >${PROJECT}___FILLOUT.vep.maf

