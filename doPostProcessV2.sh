#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

. ../config

CMOMAF=$(ls $PIPELINEDIR/variants/Proj*CMO_MAF.txt)
BAMDIR=$PIPELINEDIR/alignments

WESFBIN=~/Code/Pipelines/CBE/Variant/PostProcessV2/wes-filters
POSTDIR=~/Code/Pipelines/CBE/Variant/PostProcessV2
NORMALCOHORTBAMS=/ifs/res/share/pwg/NormalCohort/SetA/CuratedBAMsSetA

FFPEPOOLDIR=/ifs/res/share/soccin/Case_201601/Proj_06049_Pool/r_001
FFPEPOOLBAM=$FFPEPOOLDIR/alignments/Proj_06049_Pool_indelRealigned_recal_s_UD_ffpepool1_N.bam

LSFTAG=$(uuidgen)

if [ ! -e ffpePoolFill.out ]; then
echo "maf_fillout.py::FFILL"
    bsub -m commonHG -We 59 -n 24 -o LSF/ -J ${LSFTAG}_FFILL -R "rusage[mem=24]" \
         $WESFBIN/maf_fillout.py -n 24 -g b37 \
         -m $CMOMAF \
         -o ffpePoolFill.out \
         -b $FFPEPOOLBAM
fi

if [ ! -e normalCohortFill.out ]; then
echo "maf_fillout.py::NFILL"
    bsub -m commonHG -n 24 -o LSF/ -J ${LSFTAG}_NFILL -w "post_done(${LSFTAG}_FFILL)" -We 59 -R "rusage[mem=24]" \
        $WESFBIN/maf_fillout.py -n 24 -g b37 \
        -m $CMOMAF -o normalCohortFill.out \
        -b $(ls /ifs/res/share/pwg/NormalCohort/SetA/CuratedBAMsSetA/*.bam)
fi

if [ ! -e ___FILLOUT_DUP.vcf ]; then
echo "fillOutCBE::CFILL"
    bsub -m commonHG -o LSF/ -J ${LSFTAG}_CFILL -We 59 -n 24 -R "rusage[mem=22]" \
        ~/Code/FillOut/FillOut/fillOutCBE.sh \
        $BAMDIR \
        $CMOMAF \
        ___FILLOUT_DUP.vcf
fi

#SYNC CFILL

$SDIR/bSync ${LSFTAG}_CFILL

(egrep "^#" ___FILLOUT_DUP.vcf; \
    cat ___FILLOUT_DUP.vcf | egrep -v "^#" | sort | uniq) \
    >___FILLOUT.vcf

echo "vcf2MultiMAF::FILL2"
bsub -m commonHG -o LSF/ -J ${LSFTAG}_FILL2 -n 12 -R "rusage[mem=22]" \
    $POSTDIR/vcf2MultiMAF_b37.sh ___FILLOUT.vcf

$SDIR/bSync ${LSFTAG}_FILL2

#SYNC NFILL
$SDIR/bSync ${LSFTAG}_NFILL

echo "ApplyAllFilters"
$SDIR/filterMAF.sh $CMOMAF mafA

echo "Applying filter_ffpe_pool"
$WESFBIN/applyFilter.sh filter_ffpe_pool.R mafA mafB -f ffpePoolFill.out
echo "Applying filter_normal_panel"
$WESFBIN/applyFilter.sh filter_normal_panel.R mafB mafC -f normalCohortFill.out
echo "Applying filter_cohort_normals"
$WESFBIN/applyFilter.sh filter_cohort_normals.R mafC mafD -f ___FILLOUT.maf
cp mafD $(basename $PROJECTDIR)___SOMATIC_FACETS.vep.filtered.maf

