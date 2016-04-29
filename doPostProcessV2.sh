#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

. ../config

CMOMAF=$(ls $PIPELINEDIR/variants/Proj*CMO_MAF.txt)
BAMDIR=$PIPELINEDIR/alignments

WESFBIN=~/Code/Pipelines/CBE/Variant/PostProcessV2/wes-filters
POSTDIR=~/Code/Pipelines/CBE/Variant/PostProcessV2
NORMALCOHORTBAMS=/ifs/res/share/pwg/NormalCohort/SetA/CuratedBAMsSetA

bsub -m commonHG -We 59 -n 24 -o LSF/ -J FFPEFILL -R "rusage[mem=24]" \
     $WESFBIN/maf_fillout.py -n 24 -g b37 \
     -m $CMOMAF \
     -o ffpePoolFill.out \
     -b /ifs/res/share/soccin/Case_201601/Proj_06049_Pool/r_001/alignments/Proj_06049_Pool_indelRealigned_recal_s_UD_ffpepool1_N.bam

bsub -m commonHG -n 24 -o LSF/ -J NFILL -w "post_done(FFPEFILL)" -We 59 -R "rusage[mem=24]" \
    $WESFBIN/maf_fillout.py -n 24 -g b37 \
    -m $CMOMAF -o normalCohortFill.out \
    -b $(ls /ifs/res/share/pwg/NormalCohort/SetA/CuratedBAMsSetA/*.bam)


bsub -m commonHG -o LSF/ -J COHORTFILL -We 59 -n 24 -R "rusage[mem=22]" \
    ~/Code/FillOut/FillOut/fillOutCBE.sh \
    $BAMDIR \
    $CMOMAF \
    ___FILLOUT_DUP.vcf

exit

#SYNC COHORTFILL

(egrep "^#" ___FILLOUT_DUP.vcf; \
    cat ___FILLOUT_DUP.vcf | egrep -v "^#" | sort | uniq) \
    >___FILLOUT.vcf

bsub -m commonHG -o LSF/ -J FILL -n 12 -R "rusage[mem=22]" \
    $POSTDIR/vcf2MultiMAF_b37.sh ___FILLOUT.vcf

#SYNC FILL

rm split___*___FILLOUT.maf

#SYNC NFILL

$SDIR/filterMAF.sh $CMOMAF mafA

$WESFBIN/applyFilter.sh filter_ffpe_pool.R mafA mafB -f ffpePoolFill.out
$WESFBIN/applyFilter.sh filter_normal_panel.R mafB mafC -f normalCohortFill.out
$WESFBIN/applyFilter.sh filter_cohort_normals.R mafC mafD -f ___FILLOUT.maf
cp mafD $(basename $PROJECTDIR)___SOMATIC_FACETS.vep.filtered.maf

