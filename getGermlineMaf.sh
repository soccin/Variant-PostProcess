#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

VEPPATH=/opt/common/CentOS_6/vep/v79
BEDTOOLS=/opt/common/CentOS_6/bedtools/bedtools-2.22.0/bin/bedtools

source $SDIR/paths.sh

if [ "$#" != "3" ]; then
    echo "usage: $(basename $0) PROJECT_NO HAPLOTYPE_VCF TMPDIR"
    exit
fi

PROJECT=$1
VCF=$2
TDIR=$3

GENOME_BUILD=$(head -100 $VCF | fgrep "##contig=" | fgrep assembly= | head -1 | perl -ne 'm/assembly=(.*)>/; print $1')
echo GENOME_BUILD=$GENOME_BUILD
GENOME_SH=$SDIR/genomeInfo_${GENOME_BUILD}.sh
if [ ! -e "$GENOME_SH" ]; then
    echo "Unknown genome build ["${GENOME_BUILD}"]"
    exit
fi
echo "Loading genome [${GENOME_BUILD}]" $GENOME_SH
source $GENOME_SH
echo GENOME=$GENOME

mkdir -p $TDIR

if [ ! -f "$TDIR/$(basename $GENOME)" ]; then
	ln -s $GENOME $TDIR/$(basename $GENOME)
    ln -s ${GENOME}.fai $TDIR/$(basename $GENOME).fai
fi

if [ ! -f "$TDIR/germline.maf0" ]; then
    echo $0 "Generating MAF0"
    $SDIR/vcf2maf0.py -c haplotypecaller -i $VCF -o $TDIR/germline.maf0
fi
echo $0 "MAF0 ready"

$SDIR/pA_GermlineV2.py  <$TDIR/germline.maf0 >$TDIR/germline.maf1
echo $0 "MAF1 ready"
$SDIR/oldMAF2tcgaMAF.py $GENOME_BUILD $TDIR/germline.maf1 $TDIR/germline.maf2
echo $0 "MAF2 ready"


if [ ! -f "$TDIR/germline.maf2.vep" ]; then
$PERL $VCF2MAF/maf2maf.pl \
    --vep-forks 12 \
    --tmp-dir $TDIR/GERM \
    --vep-path $VEPPATH \
    --vep-data $VEPPATH \
    --ref-fasta $TDIR/$(basename $GENOME) \
    --retain-cols Center,Verification_Status,Validation_Status,Mutation_Status,Sequencing_Phase,Sequence_Source,Validation_Method,Score,BAM_file,Sequencer,Tumor_Sample_UUID,Matched_Norm_Sample_UUID,Caller \
    --custom-enst $MSK_ISOFORMS \
    --input-maf $TDIR/germline.maf2 \
    --output-maf $TDIR/germline.maf2.vep
fi

echo $0 "MAF2.VEP ready"

cat $TDIR/germline.maf2.vep \
    | egrep -v "(^#|^Hugo_Symbol)" \
    | awk '{print $5,$6-1,$7}' \
    | tr ' ' '\t'  >$TDIR/germline.maf2.bed

$BEDTOOLS slop -g $SDIR/db/human.${GENOME_BUILD}.genome -b 1 -i $TDIR/germline.maf2.bed \
    | $BEDTOOLS getfasta -tab \
    -fi $GENOME -fo $TDIR/germline.maf2.seq -bed -

$BEDTOOLS intersect -a $TDIR/germline.maf2.bed \
    -b $SDIR/db/IMPACT_410_${GENOME_BUILD}_targets_plus3bp.bed -wa \
    | $BEDTOOLS sort -i - | awk '{print $1":"$2+1"-"$3}' | uniq >$TDIR/germline.maf2.impact410

echo $0 "Making final MAF"

echo $0 "computing ExAC"

$SDIR/maf2vcfSimple.sh $GENOME_BUILD $TDIR/germline.maf2 >$TDIR/germline_maf2.vcf
cat $TDIR/germline_maf2.vcf | sed 's/^chr//' > $TDIR/germline_maf3.vcf
$SDIR/bgzip $TDIR/germline_maf3.vcf
$SDIR/tabix -p vcf $TDIR/germline_maf3.vcf.gz
/opt/common/CentOS_6/bcftools/bcftools-1.2/bin/bcftools \
     annotate --annotations $EXACDB \
     --columns AC,AN,AF --output-type v --output $TDIR/germline_maf3.exac.vcf $TDIR/germline_maf3.vcf.gz


echo $0 "Computing CMO MAF"

$SDIR/mkTaylorMAF.py $TDIR/germline.maf2.seq $TDIR/germline.maf2.impact410 $TDIR/germline_maf3.exac.vcf $TDIR/germline.maf2.vep \
    > ${PROJECT}___GERMLINE.vep.maf

echo $0 "DONE"

