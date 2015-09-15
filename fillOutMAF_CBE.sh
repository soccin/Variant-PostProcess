#!/bin/bash

GENOME=/common/data/assemblies/H.sapiens/hg19/hg19.fasta
BAMDIR=$1
BAMDIR=$(echo $BAMDIR | sed 's/\/$//')
VCF=$2
OUT=$3

INPUTS=$(ls $BAMDIR/*bam | perl -ne 'chomp; m|_(s_.*).bam|;print "--bam ",$1,":",$_,"\n"')

/home/socci/Code/Zeng/GetBaseCountsMultiSample/GetBaseCountsMultiSample \
	--filter_improper_pair 0 --fasta $GENOME \
	--vcf $VCF \
	--output $OUT \
	$INPUTS
