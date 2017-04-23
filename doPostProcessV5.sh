#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
SVERSION=$(git --git-dir=$SDIR/.git --work-tree=$SDIR describe --tags --dirty="-UNCOMMITED")

#
# Set small limit for debugging
#
JC_TIMELIMIT="-We 59"
#JC_TIMELIMIT_LONG="-We 59"
# JC_TIMELIMIT_LONG=""
# JC_TIMELIMIT_MERGE=$JC_TIMELIMIT_LONG
# JC_TIMELIMIT_CFILL=$JC_TIMELIMIT_LONG
# JC_TIMELIMIT_NFILL=$JC_TIMELIMIT_LONG
# JC_TIMELIMIT_MAFANNO=$JC_TIMELIMIT_LONG

FACETS_SUITE=/opt/common/CentOS_6/facets-suite/facets-suite-1.0.1

. ../config

LSFTAG=$(uuidgen)

PROJECTNO=$(echo $PROJECTDIR | perl -ne 'm|(Proj_[^/]*)|; print $1')
echo PROJECTNO=$PROJECTNO

