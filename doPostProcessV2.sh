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

PROJECTNO=$(echo $PROJECTDIR | perl -ne 'm|(Proj_[^/]*)|; print $1')
echo PROJECTNO=$PROJECTNO


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
        echo "Using PAIRINGFILE="$PAIRINGFILE
        echo "WARNING: Can not find PATIENT FILE"
        echo "PAIRING file used to infer normals; might not be correct"
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

exit

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

if [ ! -e ___FILLOUT.vcf ]; then
echo "fillOutCBE::CFILL"
    bsub -m commonHG -o LSF/ -J ${LSFTAG}_CFILL -We 59 -n 24 -R "rusage[mem=22]" \
        ~/Code/FillOut/FillOut/fillOutCBE.sh \
        $BAMDIR \
        $CMOMAF \
        ___FILLOUT.vcf
fi

#SYNC CFILL

$SDIR/bSync ${LSFTAG}_CFILL

echo "vcf2MultiMAF::FILL2"
bsub -m commonHG -o LSF/ -J ${LSFTAG}_FILL2 -n 12 -R "rusage[mem=22]" \
    $POSTDIR/vcf2MultiMAF_b37.sh ___FILLOUT.vcf

$SDIR/bSync ${LSFTAG}_FILL2

#SYNC NFILL
$SDIR/bSync ${LSFTAG}_NFILL

#
# Check if BIC-pipeline is applying any filters
#

BIC_FILTERS=$(egrep "^#WES-FILTER" $CMOMAF  | awk '{print $2}' | sort  | tr '\n' ';')

if [ "$BIC_FILTERS" == "" ]; then
    echo "ApplyFilters blacklist, ffpe, low_conf"
    $SDIR/filterMAF.sh $CMOMAF mafA
else
    echo "the following filters have been applied skipping SDIR/filterMAF.sh"
    echo
    echo $BIC_FILTERS
    echo
    if [ "$BIC_FILTERS" == "filter_blacklist_regions.R;filter_ffpe.R;filter_low_conf.R;" ]; then
        cp $CMOMAF mafA
    else
        echo "FATAL ERROR"
        echo "Note the filters we were expecting"
        echo "    filter_blacklist_regions.R;filter_ffpe.R;filter_low_conf.R;"
        exit 1
    fi
fi

echo "Applying filter_ffpe_pool"
$WESFBIN/applyFilter.sh filter_ffpe_pool.R mafA mafB -f ffpePoolFill.out
echo "Applying filter_normal_panel"
$WESFBIN/applyFilter.sh filter_normal_panel.R mafB mafC -f normalCohortFill.out
echo "Applying filter_cohort_normals"
$WESFBIN/applyFilter.sh filter_cohort_normals.R mafC mafD -f ___FILLOUT.maf -N _normalSamples

#
# Figure out if common variants filters was applied
# in starting CMO maf. If not do so
#

HAS_FILTER_COLUMN=$(head -100 $CMOMAF | egrep -v "^#" | head -1 | tr '\t' '\n' | fgrep FILTER)
if [ "$HAS_FILTER_COLUMN" == "" ]; then
    echo "CMO MAF did not have common_filter"
    echo "Applying filter_cohort_normals"
    $WESFBIN/applyFilter.sh filter_common_variants.R mafD mafE
    cp mafE ${PROJECTNO}___SOMATIC_FACETS.vep.filtered.maf
else
    cp mafD ${PROJECTNO}___SOMATIC_FACETS.vep.filtered.maf
fi

mv ___FILLOUT.maf ${PROJECTNO}___FILLOUT.maf