#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ $# -ne 1 ]; then
    echo "usage: postProcess.sh PipelineOutputDir"
    exit
fi

PIPELINEDIR=$1
PIPELINEDIR=$(echo $PIPELINEDIR | sed 's/\/$//')

projectNo=$(echo $PIPELINEDIR | perl -ne 'm|/Proj_([^/\s]*)|; print $1')

if [ -e "facets" ]; then
    echo "Delivery facets"
    mkdir -p $PIPELINEDIR/facets
    rsync -avP ./facets/Cval* $PIPELINEDIR/facets
fi

if [ -e "post" ]; then
    echo "Deliver post"
    mkdir -p $PIPELINEDIR/post
    rsync -avP post/Proj_${projectNo}*maf $PIPELINEDIR/post
fi

chmod -R g+w $PIPELINEDIR/facets $PIPELINEDIR/post