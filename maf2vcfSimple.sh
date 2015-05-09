#!/bin/bash
GENOMEFAI=/common/data/assemblies/H.sapiens/hg19/hg19.fasta.fai
echo "##fileformat=VCFv4.2"
echo "#CHROM POS ID REF ALT" | tr ' ' '\t'
cat $1 | egrep -v "^Hugo" \
	| awk -F"\t" '{print $5,$6,".",$11,$12}' \
	| tr ' ' '\t' | sort -k2,2n | /home/socci/bin/sortByRef.pl - $GENOMEFAI \
	| uniq  
