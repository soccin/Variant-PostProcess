#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
BICPIPEDIR=/ifs/work/socci/Pipelines/CBE/variants_pipeline

if [ "$#" != "3" ]; then
    echo "usage: getMergedMAF.sh PROJECTNO PIPELINEDIR PAIRINGFILE [GENOME]"
    exit
fi

PROJECTNO=$1
PIPELINEDIR=$2
PAIRINGFILE=$3

if [ "$#" == "4" ]; then
    GENOME=$4
else
    GENOME=b37
fi

ODIR=_mergedMAF
mkdir -p $ODIR

echo -n "fixing In/Dels..."
$SDIR/FixMultiInDel/fixMultiInDel.sh \
    $PIPELINEDIR/variants/snpsIndels/haplotypecaller/${PROJECTNO}_HaplotypeCaller.vcf \
    $ODIR/___FixInDels.vcf

echo "done"

exit

$BICPIPEDIR/haploTect_merge.pl \
    -config $BICPIPEDIR/variants_pipeline_config.txt \
    -pre $PROJECTNO \
    -pair $PAIRINGFILE \
    -species $GENOME \
    -exac_vcf /opt/common/CentOS_6/vep/v86/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz
    -output $ODIR \
    -mutect_dir $PIPELINEDIR/variants/snpsIndels/mutect \
    -hc_vcf $ODIR/___FixInDels.vcf
