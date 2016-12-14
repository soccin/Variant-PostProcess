#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
SVERSION=$(git --git-dir=$SDIR/.git --work-tree=$SDIR describe --tags --dirty="-UNCOMMITED")

#
# Set small limit for debugging
#
JC_TIMELIMIT="-We 59"

FACETS_SUITE=/opt/common/CentOS_6/facets-suite/facets-suite-1.0.1

. ../config

LSFTAG=$(uuidgen)

PROJECTNO=$(echo $PROJECTDIR | perl -ne 'm|(Proj_[^/]*)|; print $1')
echo PROJECTNO=$PROJECTNO

######################################################################
#
# Regenerate MergedMAF but first fix problem with overlapping in/del's
# from haplotype caller
#

bsub -m commonHG ${JC_TIMELIMIT} -o LSF.MERGE/ -J ${LSFTAG}_MERGE -R "rusage[mem=20]" -M 21 \
$SDIR/getMergedMAF.sh \
    $PROJECTNO \
    $PIPELINEDIR \
    $PROJECTDIR/${PROJECTNO}_sample_pairing.txt

$SDIR/bSync ${LSFTAG}_MERGE
BICMAF=_mergedMAF/${PROJECTNO}_haplotect_VEP_MAF.txt \

#
# Do wes-filters
#

BAMDIR=$PIPELINEDIR/alignments
WESFBIN=$SDIR/wes-filters
NORMALCOHORTBAMS=/ifs/res/share/pwg/NormalCohort/SetA/CuratedBAMsSetA
FFPEPOOLDIR=/ifs/res/share/soccin/Case_201601/Proj_06049_Pool/r_001
FFPEPOOLBAM=$FFPEPOOLDIR/alignments/Proj_06049_Pool_indelRealigned_recal_s_UD_ffpepool1_N.bam

if [ ! -e ffpePoolFill.out ]; then
echo "maf_fillout.py::FFILL"
    bsub -m commonHG ${JC_TIMELIMIT} -n 24 -o LSF/ -J ${LSFTAG}_FFILL -R "rusage[mem=24]" \
         $WESFBIN/maf_fillout.py -n 24 -g b37 \
         -m $BICMAF \
         -o ffpePoolFill.out \
         -b $FFPEPOOLBAM
fi

if [ ! -e normalCohortFill.out ]; then
echo "maf_fillout.py::NFILL"
    bsub -m commonHG ${JC_TIMELIMIT} -n 24 -o LSF/ -J ${LSFTAG}_NFILL -w "post_done(${LSFTAG}_FFILL)" -R "rusage[mem=24]" \
        $WESFBIN/maf_fillout.py -n 24 -g b37 \
        -m $BICMAF -o normalCohortFill.out \
        -b $(ls /ifs/res/share/pwg/NormalCohort/SetA/CuratedBAMsSetA/*.bam)
fi

if [ ! -e ___FILLOUT.vcf ]; then
echo "fillOutCBE::CFILL"
    bsub -m commonHG ${JC_TIMELIMIT} -o LSF/ -J ${LSFTAG}_CFILL -n 24 -R "rusage[mem=22]" \
        ~/Code/FillOut/FillOut/fillOutCBE.sh \
        $BAMDIR \
        $BICMAF \
        ___FILLOUT.vcf
fi

$SDIR/bSync ${LSFTAG}_CFILL

echo "vcf2MultiMAF::FILL2"
bsub -m commonHG -o LSF/ -J ${LSFTAG}_FILL2 -n 12 -R "rusage[mem=22]" \
    $SDIR/vcf2MultiMAF_b37.sh ___FILLOUT.vcf

$SDIR/bSync ${LSFTAG}_FILL2

$SDIR/bSync ${LSFTAG}_NFILL

echo "ApplyFilters blacklist, ffpe, low_conf"
$SDIR/filterMAF.sh $BICMAF mafA
echo "Applying filter_ffpe_pool"
$WESFBIN/applyFilter.sh filter_ffpe_pool.R mafA mafB -f ffpePoolFill.out
echo "Applying filter_normal_panel"
$WESFBIN/applyFilter.sh filter_normal_panel.R mafB mafC -f normalCohortFill.out

###############################################################
#
# See if there is a patient file to identify normal samples
#

PATIENTFILE=$(ls -d $PROJECTDIR/* | fgrep _sample_patient.txt)

if [ "$PATIENTFILE" != "" ]; then
    echo "Using PATIENTFILE="$PATIENTFILE
    cat $PATIENTFILE  | awk -F"\t" '$5=="Normal"{print $2}' >_normalSamples
else
    PAIRINGFILE=$(ls -d $PROJECTDIR/* | fgrep _sample_pairing.txt)
    if [ "$PAIRINGFILE" != "" ]; then
        echo "WARNING: Can not find PATIENT FILE"
        echo "PAIRING file used to infer normals; might not be correct"
        echo "Using PAIRINGFILE="$PAIRINGFILE
        cat $PAIRINGFILE  | cut -f1 | sort | uniq >_normalSamples
    else
        echo "FATAL ERROR: Cannot find PATIENT nor PAIRINGFILE"
        echo "Can not determine normal samples"
        exit 1
    fi
fi

NUM_NORMALS=$(wc -l _normalSamples | awk '{print $1}')
if [ "$NUM_NORMALS" == "0" ]; then
    echo
    echo "FATAL ERROR: Found 0 Normals; if this is really true implement override"
    echo
    exit 1
fi

# Finished getting normal samples
###############################################################

echo "Applying filter_cohort_normals"
$WESFBIN/applyFilter.sh filter_cohort_normals.R mafC mafD -f ___FILLOUT.maf -N _normalSamples

#
# Figure out if common variants filters was applied
# in starting CMO maf. If not do so
#

HAS_FILTER_COLUMN=$(head -100 $BICMAF | egrep -v "^#" | head -1 | tr '\t' '\n' | fgrep FILTER)
if [ "$HAS_FILTER_COLUMN" == "" ]; then
    echo "CMO MAF did not have common_filter"
    echo "Applying filter_cohort_normals"
    $WESFBIN/applyFilter.sh filter_common_variants.R mafD mafE
    cp mafE mafFinal
else
    cp mafD mafFinal
fi

#
# Get rid of GL chromosomes
#

cat mafFinal | awk -F"\t" '$5 !~ /GL/{print $0}' >${PROJECTNO}___SOMATIC.vep.filtered.V3.maf

cat ___FILLOUT.maf | awk -F"\t" '$5 !~ /GL/{print $0}' >${PROJECTNO}___FILLOUT.V3.maf

###################################################################################
# Add facets
#

bsub -m commonHG ${JC_TIMELIMIT} -o LSF.FACETS/ -J ${LSFTAG}_FACETS -R "rusage[mem=20]" -M 21 \
$FACETS_SUITE/facets mafAnno \
    -m ${PROJECTNO}___SOMATIC.vep.filtered.V3.maf\
    -f $PIPELINEDIR/variants/copyNumber/facets/facets_mapping.txt \
    -o ${PROJECTNO}___SOMATIC.vep.filtered.facets.V3.maf

$SDIR/bSync ${LSFTAG}_FACETS
