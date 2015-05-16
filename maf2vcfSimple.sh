#!/bin/bash
GENOMEFAI=/common/data/assemblies/H.sapiens/hg19/hg19.fasta.fai

TDIR=$(dirname $1)
mkdir $TDIR/FILL

/opt/common/CentOS_6/bin/v1/perl /opt/common/CentOS_6/vcf2maf/v1.5.2/maf2vcf.pl \
    --input-maf $1 \
    --ref-fasta $TDIR/hg19.fasta \
    --output-dir $TDIR/FILL

echo "##fileformat=VCFv4.2"
echo "#CHROM POS ID REF ALT" | tr ' ' '\t'
cat $TDIR/FILL/*vcf \
    | fgrep -v "#" | cut -f-5 \
    | sort -k2,2n | sortByRef.pl - $GENOMEFAI \
    | uniq


