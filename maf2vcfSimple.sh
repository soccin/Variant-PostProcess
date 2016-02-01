#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"

source $SDIR/paths.sh

GENOME_BUILD=$1
shift
echo BUILD=${GENOME_BUILD}
GENOME_SH=$SDIR/genomeInfo_${GENOME_BUILD}.sh
if [ ! -e "$GENOME_SH" ]; then
    echo "Unknown genome build ["${GENOME_BUILD}"]"
    exit
fi
echo "Loading genome [${GENOME_BUILD}]" $GENOME_SH
source $GENOME_SH
echo GENOME=$GENOME

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


