#!/bin/bash

# Wrapper around bsub

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ $# -ne 2 ]; then
	echo "usage: postProcess.sh ProjectDir PipelineOutputDir"
	exit
fi

PROJECTDIR=$1
PIPELINEDIR=$2

projectNo=$(echo $PROJECTDIR | perl -ne 'm|/Proj_([^/\s]*)|; print $1')

echo $PROJECTDIR
echo $PIPELINEDIR
echo $PROJECTDIR/*_sample_pairing.txt
echo $projectNo

bsub -J POST_$projectNo -n 24 -R "rusage[mem=128]" -o LSF.POST/ \
    ~/Code/Pipelines/CBE/Variant/PostProcessV1/postProcess.sh \
    $PROJECTDIR/*_sample_pairing.txt \
    $PIPELINEDIR

