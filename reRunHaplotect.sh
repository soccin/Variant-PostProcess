#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
SVERSION=$(git --git-dir=$SDIR/.git --work-tree=$SDIR describe --tags --dirty="-UNCOMMITED")

BICPIPEDIR=/ifs/work/socci/Pipelines/CBE/variants_pipeline

if [ "$#" != "3" ]; then
    echo "usage: reRunHaplotect.sh PROJECTNO PIPELINEDIR PAIRINGFILE [GENOME]"
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

ODIR=_reRunHaplotect
mkdir -p $ODIR

echo -n "running haploTect_merge..."
$BICPIPEDIR/haploTect_merge.pl \
    -svnRev "reRunHaplotect.sh::$SVERSION" \
    -config $BICPIPEDIR/variants_pipeline_config.txt \
    -pre $PROJECTNO \
    -pair $PAIRINGFILE \
    -species $GENOME \
    -exac_vcf /opt/common/CentOS_6/vep/v86/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz \
    -output $ODIR \
    -mutect_dir $PIPELINEDIR/variants/snpsIndels/mutect \
    -hc_vcf $PIPELINEDIR/variants/snpsIndels/haplotypecaller/${PROJECTNO}_HaplotypeCaller.vcf

echo "done"

