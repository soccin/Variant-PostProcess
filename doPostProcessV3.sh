#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
SVERSION=$(git --git-dir=$SDIR/.git --work-tree=$SDIR describe --tags --dirty="-UNCOMMITED")

export PATH=$SDIR/opt/bin:$PATH
unset R_LIBS

bsub () {
    echo bsub $*
}

echo ""
echo "   LSF_ENV_ARGS=\"$LSF_ENV_ARGS\""
echo ""

#
# Set small limit for debugging
# -W option no longer used on LUNA
JC_TIMELIMIT="-W 59 $LSF_ENV_ARGS"
JC_TIMELIMIT_LONG="-W 359 $LSF_ENV_ARGS"
JC_TIMELIMIT_MERGE=$JC_TIMELIMIT_LONG
JC_TIMELIMIT_CFILL=$JC_TIMELIMIT_LONG
JC_TIMELIMIT_NFILL=$JC_TIMELIMIT_LONG
JC_TIMELIMIT_MAFANNO=$JC_TIMELIMIT_LONG

FACETS_SUITE=/opt/common/CentOS_6/facets-suite/facets-suite-1.0.1

WESFBIN=$SDIR/wes-filters
#POSTRESDIR=/ifs/res/share/pwg/
POSTRESDIR=/juno/res/bic/shared/pwg
NORMALCOHORTBAMS=$POSTRESDIR/NormalCohort/SetA/CuratedBAMsSetA
FFPEPOOLDIR=$POSTRESDIR/FFPEPool/Case_201601/Proj_06049_Pool/r_001
FFPEPOOLBAM=$FFPEPOOLDIR/alignments/Proj_06049_Pool_indelRealigned_recal_s_UD_ffpepool1_N.bam

if [ ! -e $NORMALCOHORTBAMS ]; then
    echo -e "\n\nERROR: Missing the normal cohort BAMS\n\n"
    exit 1
fi

if [ ! -e $FFPEPOOLBAM ]; then
    echo -e "\n\nERROR: Missing the FFPE POOL BAM"
    exit 1
fi

. ../config

BAMDIR=$PIPELINEDIR/alignments

LSFTAG=$(uuidgen)

PROJECTNO=$(echo $PROJECTDIR | perl -ne 'm|(Proj_[^/]*)|; print $1')
echo PROJECTNO=$PROJECTNO

echo "Check BIC MAF version"
BICMAF=$PIPELINEDIR/variants/snpsIndels/haplotect/${PROJECTNO}_haplotect_VEP_MAF.txt
SVNREV=$(head $BICMAF | fgrep SVN | awk '{print $3}')
echo "MAF SVN REV = $SVNREV"
if [ "$SVNREV" == "" ]; then
    echo -e "\n\n No SVN TAG, setting version to 0"
    SVNREV=0
fi

if [ "$SVNREV" -lt "5700" ]; then
    echo -e "\n\n    BICMAF prior to 5699 fix (mutect filter bug)\n"
    echo -e "    Rerunning later haplotect\n\n"

    ######################################################################
    #
    # Regenerate HaplotectMAF with later version of pipeline code
    #

    bsub ${JC_TIMELIMIT_MERGE} -o LSF.MERGE/ -J ${LSFTAG}_MERGE -R "rusage[mem=20]" \
    $SDIR/reRunHaplotect.sh \
        $PROJECTNO \
        $PIPELINEDIR \
        $PROJECTDIR/${PROJECTNO}_sample_pairing.txt

    $SDIR/bSync ${LSFTAG}_MERGE
    BICMAF=_reRunHaplotect/${PROJECTNO}_haplotect_VEP_MAF.txt


else
    echo "Use BIC maf"
    echo $BICMAF
fi


if [ ! -e $BICMAF ]; then
    echo -e "\n\nCan not find BIC MAF"
    exit 1
fi

#
# Do wes-filters
#

if [ ! -e ffpePoolFill.out ]; then
echo "maf_fillout.py::FFILL"
    bsub ${JC_TIMELIMIT} -n 24 -o LSF/ \
	-J ${LSFTAG}_FFILL -R "rusage[mem=1]" \
         $WESFBIN/maf_fillout.py -n 24 -g b37 \
         -m $BICMAF \
         -o ffpePoolFill.out \
         -b $FFPEPOOLBAM
fi

if [ ! -e normalCohortFill.out ]; then
echo "maf_fillout.py::NFILL"
    bsub  ${JC_TIMELIMIT_NFILL} -n 24 -o LSF/ -J ${LSFTAG}_NFILL -w "post_done(${LSFTAG}_FFILL)" -R "rusage[mem=1]" \
        $WESFBIN/maf_fillout.py -n 24 -g b37 \
        -m $BICMAF -o normalCohortFill.out \
        -b $(ls $NORMALCOHORTBAMS/*.bam)
fi

if [ ! -e ___FILLOUT.vcf ]; then
echo "fillOutCBE::CFILL"
    bsub  ${JC_TIMELIMIT_CFILL} -o LSF/ \
      -J ${LSFTAG}_CFILL -n 48 -R "rusage[mem=3]" \
        ~/Code/FillOut/FillOut/fillOutCBE.sh \
        $BAMDIR \
        $BICMAF \
        ___FILLOUT.vcf
fi

$SDIR/bSync ${LSFTAG}_CFILL

echo "vcf2MultiMAF::FILL2"
#bsub  ${JC_TIMELIMIT_LONG} -o LSF/ -J ${LSFTAG}_FILL2 -n 12 -R "rusage[mem=2]" \
bsub  ${JC_TIMELIMIT_LONG} -o LSF/ -J ${LSFTAG}_FILL2 \
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

EXIT_CODE=$?

if [ "$EXIT_CODE" != "0" ]; then
    echo "ERROR IN applyFilter.sh filter_cohort_normals.R"
    exit 1
fi


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

cat mafFinal | awk -F"\t" '$5 !~ /GL/{print $0}' >${PROJECTNO}___SOMATIC.vep.filtered.V3b.maf

cat ___FILLOUT.maf | awk -F"\t" '$5 !~ /GL/{print $0}' >${PROJECTNO}___FILLOUT.V3b.maf

###################################################################################
# Add facets
#

cat $PIPELINEDIR/variants/copyNumber/facets/facets_mapping.txt \
    | perl -pe "s|/ifs/.*variants/copyNumber/facets/|"$PIPELINEDIR"/variants/copyNumber/facets/|" \
    > _facets_mapping_fixed.txt

bsub  ${JC_TIMELIMIT_MAFANNO} -o LSF.FACETS/ -J ${LSFTAG}_FACETS -R "rusage[mem=40]" \
$FACETS_SUITE/facets mafAnno \
    -m ${PROJECTNO}___SOMATIC.vep.filtered.V3b.maf\
    -f _facets_mapping_fixed.txt \
    -o ${PROJECTNO}___SOMATIC.vep.filtered.facets.V3b.maf

EXIT=$?

$SDIR/bSync ${LSFTAG}_FACETS

if [ "$EXIT" != "0" ]; then
    echo
    echo FACETS ERROR EXIT=$EXIT
    echo
    exit $EXIT
fi

