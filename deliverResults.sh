#!/bin/bash

. ../config

ln -s $PIPELINEDIR/variants/copyNumber/facets $PIPELINEDIR
mkdir $PIPELINEDIR/post
cp Proj_*___SOMATIC_FACETS.vep.filtered.maf $PIPELINEDIR/post
cp ___FILLOUT.maf $PIPELINEDIR/post/Proj_${projectNo}___FILLOUT.maf

