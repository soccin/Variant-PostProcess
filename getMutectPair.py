#!/usr/bin/env python2.7

import sys

if len(sys.argv)!=3:
    print >>sys.stderr, "Usage: getMutectPair.py PAIRINGFILE MUTECT_VCF"
    sys.exit(-1)

pairingFile=sys.argv[1]
vcfFile=sys.argv[2]

pairs=dict()
with open(pairingFile) as fp:
    for line in fp:
        (normal,tumor)=line.strip().split()
        if normal=="na" or tumor=="na":
            continue
        tag="_%s_%s_mutect_calls.vcf" % (normal,tumor)
        pairs[tag]=(normal,tumor)

for pi in pairs:
    if vcfFile.endswith(pi):
        print "normal:=%s tumor:=%s" % pairs[pi]
