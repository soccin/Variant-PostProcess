#!/bin/bash

if [ "$#" != "1" ]; then
    echo usage getGenomeBuild.sh BAM
    exit
fi

GENOME_MD5=$(samtools view -H $1 | egrep "^@SQ" | cut -f-3 | sort  | md5sum - | awk '{print $1}')

case $GENOME_MD5 in
    b879c678e7fd80718cf20d10c6b846e4)
    # b37 gatk /ifs/depot/assemblies/H.sapiens/b37/b37.dict
    echo "b37"
    ;;

    5b4e380a6b4fc3494cfc66c917d41b37)
    # UCSC hg19 /ifs/depot/assemblies/H.sapiens/hg19/hg19.dict
    echo "hg19"
    ;;

    d660fd17a979374182d3ba8b6d76cac0)
    # UCSC mm10 /ifs/depot/assemblies/M.musculus/mm10/mm10.dict
    echo "mm10"
    ;;

    34839afd79d8b772037ed7a0e0a4f9c3)
    # UCSC mm10
    echo "mm10_hBRAF_V600E"
    ;;

    *)
    echo "unknown" $GENOME_MD5
    ;;
esac

