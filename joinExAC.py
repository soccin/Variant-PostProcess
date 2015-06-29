#!/usr/bin/env python2.7

import sys
import csv
from itertools import izip
from util import *

def cvtChrom(x):
    if x.isdigit():
        return int(x)
    else:
        return x

if len(sys.argv)!=3:
    print >>sys.stderr, "Usage: joinExAC.py exac.vcf maf"
    sys.exit()

exacFile=sys.argv[1]
origMAFFile=sys.argv[2]

exacDb=dict()
with open(exacFile) as fp:
    line=fp.readline()
    while line.startswith("##"):
        line=fp.readline()
    header=line[1:].strip().split()
    cin=csv.DictReader(fp,fieldnames=header,delimiter="\t")
    for r in cin:
        if r["INFO"]!=".":
            info=dict()
            parseInfo=[x.split("=") for x in r["INFO"].split(";")]
            for ((key,val),cType) in izip(parseInfo,(int,int,float)):
                info[key]=cType(val)
        else:
            info=None

        (chrom,start,end,ref,alt)=vcf2mafEvent(r["CHROM"],r["POS"],r["REF"],r["ALT"])
        exacDb["chr%s:%s-%s" % (chrom,start,end)]=info

events=dict()
with open(origMAFFile) as fp:
    header=fp.readline()
    while header[0]=="#":
        print header,
        header=fp.readline()
    inFields=header.strip().split("\t")
    cin=csv.DictReader(fp,inFields,delimiter="\t")
    outFields=cin.fieldnames+["ExAC_AC","ExAC_AF","ExAC_AN"]
    cout=csv.DictWriter(sys.stdout,outFields,delimiter="\t")
    cout.writeheader()
    for r  in cin:
        if not r["Chromosome"].startswith("chr"):
            chrom="chr"+r["Chromosome"]
        else:
            chrom=r["Chromosome"]
        key="%s:%s-%s" % (chrom,r["Start_Position"],r["End_Position"])
        if not key in exacDb:
            print >>sys.stderr, "Missing Exac Annotation", key
            print >>sys.stderr, "Rec =",r
            sys.exit(-1)
        if exacDb[key]:
            r["ExAC_AC"]=exacDb[key]["AC"]
            r["ExAC_AF"]=exacDb[key]["AF"]
            r["ExAC_AN"]=exacDb[key]["AN"]
        else:
            r["ExAC_AC"]="NA"
            r["ExAC_AF"]="NA"
            r["ExAC_AN"]="NA"
        cout.writerow(r)

