#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"

source $SDIR/genomeInfo.sh

TDIR=$(dirname $1)
mkdir $TDIR/FILL

/opt/common/CentOS_6/bin/v1/perl /opt/common/CentOS_6/vcf2maf/v1.5.2/maf2vcf.pl \
    --input-maf $1 \
    --ref-fasta $TDIR/$(basename $GENOME) \
    --output-dir $TDIR/FILL

echo "##fileformat=VCFv4.2"
echo "#CHROM POS ID REF ALT" | tr ' ' '\t'
cat $TDIR/FILL/*vcf \
    | fgrep -v "#" | cut -f-5 \
    | sort -k2,2n | $SDIR/sortByRef.pl - $GENOMEFAI \
    | uniq


