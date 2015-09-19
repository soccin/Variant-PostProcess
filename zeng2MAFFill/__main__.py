#!/usr/bin/env python2.7

import sys
import csv
import copy
from collections import defaultdict

from lib import *

if len(sys.argv)!=3:
    print "usage: dmp2MAFAll.py MAF.VEP ZENGFILLOUT"
    sys.exit()

MAFFILE=sys.argv[1]
FILLFILE=sys.argv[2]

mafEvents=defaultdict(dict)
mafSamples=defaultdict(set)
with open(MAFFILE) as fp:
    VERSIONTAG=fp.readline()
    print VERSIONTAG,
    cin=csv.DictReader(fp,delimiter="\t")
    MAFHEADER=cin.fieldnames
    for r in cin:
        key=(r["Chromosome"],r["Start_Position"],r["End_Position"],
            r["Reference_Allele"],r["Tumor_Seq_Allele2"])

        mafEvents[key][r["Tumor_Sample_Barcode"]]=r
        mafSamples[key].add(r["Tumor_Sample_Barcode"])
        mafSamples[key].add(r["Matched_Norm_Sample_Barcode"])

output=sys.stdout
import annotateMAF
annotateMAF.printAnnotation(sys.stdout)
output.write(VEP_MAF_Ext.header()+"\n")

sampleDb=set()
fp=open(FILLFILE)
cin=csv.DictReader(fp,delimiter="\t")
if cin.fieldnames[0]=="Chrom" and cin.fieldnames[3]=="Alt":
    samples=set()
    for si in cin.fieldnames[4:]:
        sampleDb.add(si)
else:
    print >>sys.stderr, "unexpected format for mutation file"
    print >>sys.stderr, cin.fieldnames
    sys.exit()

eventDb=dict()
samples=sorted(sampleDb)

def vcf2mafEvent(chrom,pos,ref,alt):
    delta=len(ref)-len(alt)
    refN=ref
    altN=alt
    if delta==0:
        endPos=pos
        startPos=pos
    elif delta>0:
        # Deletion
        endPos=str(int(pos)+len(refN)-1)
        startPos=str(int(pos)+1)

        refN=refN[1:]
        if len(altN)==1:
            altN="-"
        else:
            altN=altN[1:]

    else:
        # Insertion
        endPos=str(int(pos)+1)
        startPos=pos

        altN=altN[1:]
        if len(refN)==1:
            refN="-"
        else:
            refN=refN[1:]

    return (chrom,startPos,endPos,refN,altN)

for rec in cin:
    r=Bunch(rec)
    (chrom,startPos,endPos,ref,alt)=vcf2mafEvent(r.Chrom,r.Pos,r.Ref,r.Alt)
    key=(chrom,startPos,endPos,ref,alt)

    if key not in mafEvents:
        print >>sys.stderr, "Fill Key =", key
        continue
        #sys.exit(1)
    s1=mafEvents[key].keys()[0]
    rec1=mafEvents[key][s1]

    maf1=VEP_MAF_Ext(rec1)
    maf1.Tumor_Sample_Barcode=""
    maf1.Matched_Norm_Sample_Barcode=""
    maf1.Validation_Status=""
    maf1.Mutation_Status=""
    maf1.Caller=""
    maf1.t_ref_count="na"
    maf1.t_alt_count="na"
    maf1.n_ref_count=""
    maf1.n_alt_count=""

    for si in samples:
        if si in mafEvents[key]:
            mafS=VEP_MAF_Ext(mafEvents[key][si])
        elif si in mafSamples[key]:
            continue
        else:
            mafS=VEP_MAF_Ext(maf1.__dict__)
            mafS.Tumor_Sample_Barcode=si
            mafS.Caller="fillOut"
            sampleDat=dict([x.split("=") for x in rec[si].split(";")])
            mafS.t_ref_count=sampleDat["RD"]
            mafS.t_alt_count=sampleDat["AD"]
        mafS.Chromosome=mafS.Chromosome[3:]
        output.write(str(mafS)+"\n")

