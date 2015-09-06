#!/bin/bash

# Wrapper around bsub

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ $# -ne 1 ]; then
	echo "usage: postProcess.sh PipelineOutputDir"
	exit
fi

PIPELINEDIR=$1

projectNo=$(echo $PIPELINEDIR | perl -ne 'm|/Proj_([^/\s]*)|; print $1')

PROJECTDIR=$(ls -d /ifs/projects/BIC/* | fgrep $projectNo)

echo $PROJECTDIR
echo $PIPELINEDIR
echo $PROJECTDIR/*_sample_pairing.txt
echo $projectNo

bsub -J POST_$projectNo -n 24 -R "rusage[mem=128]" -o LSF.POST/ \
    ~/Code/Pipelines/CBE/Variant/PostProcessV1/postProcess.sh \
    $PROJECTDIR/*_sample_pairing.txt \
    $PIPELINEDIR

