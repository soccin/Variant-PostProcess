#!/bin/bash

MAF=$1
NCOL=$(listCols $MAF | wc -l)
LINES=$(wc -l $MAF | awk '{print $1}')
echo $MAF "LINES="$LINES "NCOL="$NCOL
