#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"

source $SDIR/genomeInfo.sh
source $SDIR/paths.sh

TDIR=$(dirname $1)
mkdir $TDIR/FILL

$PERL $VCF2MAF/maf2vcf.pl \
    --input-maf $1 \
    --ref-fasta $TDIR/$(basename $GENOME) \
    --output-dir $TDIR/FILL

echo "##fileformat=VCFv4.2"
echo "#CHROM POS ID REF ALT" | tr ' ' '\t'
cat $TDIR/FILL/*vcf \
    | fgrep -v "#" | cut -f-5 \
    | sort -k2,2n | $SDIR/sortByRef.pl - $GENOMEFAI \
    | uniq


