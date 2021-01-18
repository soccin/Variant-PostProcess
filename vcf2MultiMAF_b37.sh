#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

BEDTOOLS=/opt/common/CentOS_6/bedtools/bedtools-2.22.0/bin/bedtools
PERL=/opt/common/CentOS_6-dev/perl/perl-5.22.0/bin/perl
PYTHON=/opt/common/CentOS_6-dev/bin/current/python

VEPPATH=/opt/common/CentOS_6/vep/v86
VCF2MAF=/opt/common/CentOS_6/vcf2maf/v1.6.11
MSK_ISOFORMS=$VCF2MAF/data/isoform_overrides_at_mskcc

ln -s /juno/depot/assemblies/H.sapiens/b37/b37.fasta
ln -s /juno/depot/assemblies/H.sapiens/b37/b37.fasta.fai
GENOME=b37.fasta

VCF=$1

SAMPS=$(cat $VCF | fgrep "#CHROM" | cut -f10- | tr '\t' ' ')

BASE=$(basename $VCF | sed 's/.vcf//')

for si in $SAMPS; do
    echo ${BASE}___${si}

    $PERL $VCF2MAF/vcf2maf.pl \
        --vep-forks 12 \
        --input-vcf $VCF \
        --vep-path $VEPPATH \
        --vep-data $VEPPATH \
        --ref-fasta $GENOME \
        --custom-enst $MSK_ISOFORMS \
        --filter-vcf $VEPPATH/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz \
        --tumor-id $si \
        --output-maf split___${BASE}___${si}___FILLOUT.maf

done

(cat $SDIR/_MAF_HEADER ; egrep -hv "(^#|^Hugo)" split___${BASE}___*) > ${BASE}.maf
