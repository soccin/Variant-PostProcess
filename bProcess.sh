#!/bin/bash

# Wrapper around bsub

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ $# -ne 1 ]; then
	echo "usage: postProcess.sh PipelineOutputDir"
	exit
fi

PIPELINEDIR=$1

projectNo=$(echo $PIPELINEDIR | perl -ne 'm|/Proj_([^/\s]*)|; print $1')

PROJECTDIR=$(find /ifs/projects/BIC -type d | fgrep -v drafts | egrep "Proj_$projectNo$")

echo PROJECTDIR=$PROJECTDIR
echo PIPELINEDIR=$PIPELINEDIR
echo pairingFile=$PROJECTDIR/*_sample_pairing.txt
echo projectNo=$projectNo


bsub -o LSF.POST/ -J POST_$projectNo -n 24 -R "rusage[mem=64]" \
    ~/Code/Pipelines/CBE/Variant/PostProcessV1/postProcess.sh \
    $PROJECTDIR/*_sample_pairing.txt \
    $PIPELINEDIR

