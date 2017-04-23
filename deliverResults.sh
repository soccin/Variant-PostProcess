#!/bin/bash

echo "NEED TO FIX THIS FOR V3"
exit

if [ ! -e ../config ]; then
    echo "You are in the wrong directory, need to be in post directory"
    echo "can not find config file [../config]"
    exit
fi

. ../config

#ln -s $PIPELINEDIR/variants/copyNumber/facets $PIPELINEDIR
mkdir $PIPELINEDIR/post
rsync -avP Proj_*___SOMATIC_FACETS.vep.filtered.maf $PIPELINEDIR/post
rsync -avP ___FILLOUT.maf $PIPELINEDIR/post/Proj_${projectNo}___FILLOUT.maf

GERMLINEMAF=$(ls | fgrep ___GERMLINE.vep.maf)
if [ -e "$GERMLINEMAF" ]; then
	rsync -avP $GERMLINEMAF $PIPELINEDIR/post
fi
