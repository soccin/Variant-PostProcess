#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

PIPELINEDIR=$1


#./FixMultiInDel/fixMultiInDel.sh /ifs/res/seq/thompsonc/intlekoa/Proj_06265_EO/r_001/variants/snpsIndels/haplotypecaller/Proj_06265_EO_HaplotypeCaller.vcf

/ifs/work/socci/Pipelines/CBE/variants_pipeline/haploTect_merge.pl \
    -pair /ifs/projects/BIC/variant/Proj_06265_EO/Proj_06265_EO_sample_pairing.txt \
    -hc_vcf Proj_06265_EO_HaplotypeCaller___FixInDels.vcf \
    -mutect_dir /ifs/res/seq/thompsonc/intlekoa/Proj_06265_EO/r_001/variants/snpsIndels/mutect \
    -pre Proj_nds \
    -output /home/socci/Code/Pipelines/CBE/Variant/CallSomaticIndelHaplotype/output \
    -species b37 \
    -config /ifs/work/socci/Pipelines/CBE/variants_pipeline/variants_pipeline_config.txt \
    -exac_vcf /opt/common/CentOS_6/vep/v86/ExAC_nonTCGA.r0.3.1.sites.vep.vcf.gz
