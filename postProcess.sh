#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ $# -lt 2 ]; then
	echo "usage: postProcess.sh PairingFile PipelineOutputDir [PROJNO]"
	exit
fi

source $SDIR/paths.sh



PAIRING=$1
PIPEOUT=$2
PIPEOUT=$(echo $PIPEOUT | sed 's/\/$//')

if [ $# -eq 3 ]; then
    PROJECT=$3
else
    PROJECT=$(echo $PIPEOUT | perl -ne 'm[(/|^)(Proj_[^/\s]*)]; print $2')
    if [ "$PROJECT" == "" ]; then
        echo "ERROR unable to parse project number from pipeline output dir"
        echo $PIPEOUT
        exit 1
    fi
fi
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

source $SDIR/funcs.sh

TDIR=_scratch
mkdir -p $TDIR

ln -s $GENOME $TDIR/$(basename $GENOME)

HAPLOTYPEVCF=$(getHaplotypeVCF $PIPEOUT)

echo HAPLOTYPEVCF=$HAPLOTYPEVCF

# Germline calls

if [ ! -f "$TDIR/germline_maf3.exac.vcf" ]; then
    bsub -o LSF/ -J GERM_${PROJECT} \
        -n 12 -We 59 -R "rusage[mem=32]" \
        $SDIR/getGermlineMaf.sh ${GENOME_BUILD} ${PROJECT} \
        $HAPLOTYPEVCF \
        $TDIR
fi

#
# Get indels from Hapolotype caller
#


HAPMAF=${PROJECT}___qSomHC_InDels__TCGA_MAF.txt

if [ ! -f "$TDIR/$HAPMAF" ]; then
    $PYTHON $SDIR/vcf2maf0.py -c haplotypecaller -p $PAIRING -i $HAPLOTYPEVCF \
        -o $TDIR/hap_maf0
    $PYTHON $SDIR/pA_qSomHC.py <$TDIR/hap_maf0 >$TDIR/hap_maf1
    $PYTHON $SDIR/oldMAF2tcgaMAF.py ${GENOME_BUILD} $TDIR/hap_maf1 $TDIR/hap_maf2
    $PYTHON $SDIR/indelOnly.py <$TDIR/hap_maf2 >$TDIR/hap_maf2b
    $PYTHON $SDIR/normalizeInDels.py $TDIR/hap_maf2b $TDIR/$HAPMAF
fi

echo $0 "Done with haplotype processing ..."

#
# Get DMP re-filtered MAF from mutect
#

MUTECTDIR=$(getMutectDir $PIPEOUT)

echo $0 $MUTECTDIR

if [ ! -f "$TDIR/merge_maf3" ]; then
    for vcf in $MUTECTDIR/*vcf; do
        BASE=$(basename $vcf | sed 's/.vcf//')
		PAIR=$($PYTHON $SDIR/getMutectPair.py $PAIRING $vcf)
		normal=$(echo $PAIR | perl -ne '/normal:=(\S+) tumor:=(\S+)$/; print $1')
		tumor=$(echo $PAIR | perl -ne '/normal:=(\S+) tumor:=(\S+)$/; print $2')
        echo $vcf, $normal, $tumor
        $PYTHON $SDIR/vcf2maf0.py -c mutect -p $PAIRING \
            -t $tumor -n $normal -i $vcf \
            -o $TDIR/mt_maf0
        $PYTHON $SDIR/DMP_rescue.py  <$TDIR/mt_maf0 >$TDIR/mt_maf1
        $PYTHON $SDIR/oldMAF2tcgaMAF.py ${GENOME_BUILD} $TDIR/mt_maf1 $TDIR/mt_maf2
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
    --species mus_musculus \
    --ncbi-build GRCm38 \
	--retain-cols Center,Verification_Status,Validation_Status,Mutation_Status,Sequencing_Phase,Sequence_Source,Validation_Method,Score,BAM_file,Sequencer,Tumor_Sample_UUID,Matched_Norm_Sample_UUID,Caller \
    --custom-enst $MSK_ISOFORMS \
	--input-maf $TDIR/merge_maf3 \
	--output-maf $TDIR/merge_maf3.vep

fi


cat $TDIR/merge_maf3.vep \
    | egrep -v "(^#|^Hugo_Symbol)" \
    | awk '{print $5,$6-1,$7}' \
    | tr ' ' '\t'  >$TDIR/merge_maf3.bed

$BEDTOOLS slop -g $SDIR/db/${GENOME_BUILD}.genome -b 1 -i $TDIR/merge_maf3.bed \
    | $BEDTOOLS getfasta -tab \
    -fi $GENOME -fo $TDIR/merge_maf3.seq -bed -

head -100 merge_maf3.vep | egrep "^#" > ${PROJECT}___SOMATIC.vep.maf
python2.7 $SDIR/annotateMAF.py >> ${PROJECT}___SOMATIC.vep.maf
egrep -v "^#" merge_maf3.vep >> ${PROJECT}___SOMATIC.vep.maf
