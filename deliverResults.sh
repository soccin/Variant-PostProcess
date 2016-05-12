#!/bin/bash

. ../config

ln -s $PIPELINEDIR/variants/copyNumber/facets $PIPELINEDIR
mkdir $PIPELINEDIR/post
rsync -avP Proj_*___SOMATIC_FACETS.vep.filtered.maf $PIPELINEDIR/post
rsync -avP ___FILLOUT.maf $PIPELINEDIR/post/Proj_${projectNo}___FILLOUT.maf

