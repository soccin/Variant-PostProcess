#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

HAPMAF=$1
GENOME=$2

PAD=250

#
# Get all the IN/DEL events from a VCF
# And convert to a BED file, with some 
# extra padding around event. 
#

cat $HAPMAF \
	| egrep -v "^#" \
	| awk '{print $1,$2-1,$2,length($4),length($5)}' \
	| awk '$4>$5{print $1,$2,$3+$4} $5>$4{print $1,$2,$3+$5}' \
	| tr ' ' '\t' \
	| bedtools slop -b $PAD -i - -g $GENOME \
	| sort -k1,1V -k2,2n \
	| bedtools merge -i -
