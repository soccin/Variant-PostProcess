#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
SVERSION=$(git --git-dir=$SDIR/.git --work-tree=$SDIR describe --always --long)
VTAG="$(basename $SDIR)/$(basename $0) VERSION=$SVERSION"

usage() {
    echo "filterMAF.sh IN_MAF OUT_MAF"
    echo
    echo "    Apply several of the wes-filters."
    echo ""
    echo "  "$VTAG
    echo
    exit
}

if [ "$#" -lt "2" ]; then
    usage
fi

MAFIN=$1
MAFOUT=$2

#
# Check if MAF has proper version header
# If not add it.
#

TMPTAG=_$(uuidgen)_

HEADER=$(head -1 $MAFIN)
if [[ ! "$HEADER" =~ /^#/ ]]; then
    echo "#version 2.4" > ${TMPTAG}.maf0
fi

# Add version tag

echo "#BIC::variant_pipeline SVN:r4705+" >>${TMPTAG}.maf0
echo "#$VTAG" >>${TMPTAG}.maf0
cat $MAFIN | egrep -v "^#" >>${TMPTAG}.maf0

echo "Applying filter_blacklist_regions"
$SDIR/wes-filters/applyFilter.sh filter_blacklist_regions.R \
    ${TMPTAG}.maf0 ${TMPTAG}.maf1

echo "Applying filter_low_conf"
$SDIR/wes-filters/applyFilter.sh filter_low_conf.R \
    ${TMPTAG}.maf1 ${TMPTAG}.maf2

echo "Applying filter_ffpe"
$SDIR/wes-filters/applyFilter.sh filter_ffpe.R \
    ${TMPTAG}.maf2 ${TMPTAG}.maf3

mv ${TMPTAG}.maf3 $MAFOUT

rm ${TMPTAG}*

