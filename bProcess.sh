#!/bin/bash

# Wrapper around bsub

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ $# -lt 1 ]; then
	echo "usage: postProcess.sh PipelineOutputDir [PROJECTDIR]"
	exit
fi

PIPELINEDIR=$1

projectNo=$(echo $PIPELINEDIR | perl -ne 'm|/Proj_([^/\s]*)|; print $1')

if [ $# -eq 1 ]; then

	NUMDIRS=$(find /ifs/projects/BIC /ifs/projects/CMO -type d | egrep -v "(drafts|archive)" | egrep "Proj_$projectNo$" | wc -l)
	PROJECTDIR=$(find /ifs/projects/BIC /ifs/projects/CMO -type d | egrep -v "(drafts|archive)" | egrep "Proj_$projectNo$")
	SCRIPT=$(basename $0)
	if [ "$NUMDIRS" != "1" ]; then
	    echo $SCRIPT :: Problem finding project files for Proj_$projectNo
	    echo $SCRIPT NUMDIRS=$NUMDIRS
	    echo
	    exit
	fi

else

	PROJECTDIR=$2

fi

echo $SCRIPT PROJECTDIR=\"$PROJECTDIR\"
echo PIPELINEDIR=$PIPELINEDIR
echo pairingFile=$PROJECTDIR/*_sample_pairing.txt
echo projectNo=$projectNo


bsub -o LSF.POST/ -J POST_$projectNo -n 12 -We 59 -R "rusage[mem=64]" \
    $SDIR/postProcess.sh \
    $PROJECTDIR/*_sample_pairing.txt \
    $PIPELINEDIR

