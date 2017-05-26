#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

BEDTOOLS=/opt/common/CentOS_6/bedtools/bedtools-2.22.0/bin/bedtools
PERL=/opt/common/CentOS_6-dev/perl/perl-5.22.0/bin/perl
PYTHON=/opt/common/CentOS_6-dev/bin/current/python

VEPPATH=/opt/common/CentOS_6/vep/v86
VCF2MAF=/opt/common/CentOS_6/vcf2maf/v1.6.11
MSK_ISOFORMS=$VCF2MAF/data/isoform_overrides_at_mskcc

VCF=$1
GENOME=$2

case $GENOME in

    b37)
    ln -s /ifs/depot/assemblies/H.sapiens/b37/b37.fasta
    ln -s /ifs/depot/assemblies/H.sapiens/b37/b37.fasta.fai
    GENOME=b37.fasta
    ;;

    mm10)
    ln -s /ifs/depot/assemblies/M.musculus/mm10/mm10.fasta
    ln -s /ifs/depot/assemblies/M.musculus/mm10/mm10.fasta.fai
    GENOME=mm10.fasta
    ;;

    *)
    echo "Unknown GENOME [$GENOME]"
    exit -1
    ;;

esac

SAMPS=$(cat $VCF | fgrep "#CHROM" | cut -f10- | tr '\t' ' ')

BASE=$(basename $VCF | sed 's/.vcf//')

echo "***********************************************************"
echo
echo "THIS IS BROKEN; DOES NOT WORK FOR MOUSE"
echo
echo
exit -1

for si in $SAMPS; do
    echo ${BASE}___${si}

    $PERL $VCF2MAF/vcf2maf.pl \
        --vep-forks 12 \
        --input-vcf $VCF \
        --vep-path $VEPPATH \
        --vep-data $VEPPATH \
###
###
exit

# remove this for mouse


        --filter-vcf $VEPPATH/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz \
        --ref-fasta $GENOME \
        --tumor-id $si \
        --output-maf split___${BASE}___${si}___FILLOUT.maf

done

MAF1=$(ls split___${BASE}___* | head -1)
head -100 $MAF1 | egrep "(^#|^Hugo)" >${BASE}.maf
egrep -hv "(^#|^Hugo)" split___${BASE}___* >> ${BASE}.maf
