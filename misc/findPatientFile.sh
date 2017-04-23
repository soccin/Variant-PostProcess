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

