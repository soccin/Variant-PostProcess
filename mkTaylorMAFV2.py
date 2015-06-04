#!/usr/bin/env python2.7

import sys
import csv
from itertools import izip

def cvtChrom(x):
    if x.isdigit():
        return int(x)
    else:
        return x

if len(sys.argv)!=7:
    print >>sys.stderr, "Usage: mkTaylorMAF.py TriNucFile IMPACT410 ExAC FACETS.SEG FACETS.SAMPLE OrigMAF"
    sys.exit()

seqDataFile=sys.argv[1]
impact410File=sys.argv[2]
exacFile=sys.argv[3]
facetsSegFile=sys.argv[4]
facetsSampFile=sys.argv[5]
origMAFFile=sys.argv[6]

seqDb=dict()
with open(seqDataFile) as fp:
    for line in fp:
        (tag, seq)=line.strip().split()
        if len(seq)==3:
            (chrom,region)=tag.split(":")
            (start,end)=[int(x) for x in region.split("-")]
            pos=end-1
            seqDb["%s:%d-%d" % (chrom,pos,pos)]=seq.upper()

impact410=set()
with open(impact410File) as fp:
    for line in fp:
        impact410.add(line.strip())

def vcf2mafEvent(chrom,pos,ref,alt):
    delta=len(ref)-len(alt)
    refN=ref
    altN=alt
    if delta==0:
        endPos=pos
        startPos=pos
    elif delta>0:
        endPos=str(int(pos)+len(refN)-1)
        startPos=str(int(pos)+1)
        refN=refN[1:]
        if len(altN)==1:
            altN='-'
        else:
            altN=altN[1:]
    else:
        endPos=str(int(pos)+1)
        startPos=pos
        refN="-"
        altN=altN[1:]
    return (chrom,startPos,endPos,refN,altN)

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

            (chrom,start,end,ref,alt)=vcf2mafEvent(r["CHROM"],r["POS"],r["REF"],r["ALT"])

            exacDb["chr%s:%s-%s" % (chrom,start,end)]=info

facetSampDb=dict()
CVAL=str(300)
with open(facetsSampFile) as fp:
    cin=csv.DictReader(fp,delimiter="\t")
    for r in cin:
        facetSampDb[(r["Tumor"],r["Normal"])]=r

facetSegCol="""
ID chrom loc.start loc.end seg num.mark nhet
cnlr.median mafR segclust cnlr.median.clust mafR.clust
cf tcn lcn cf.em tcn.em lcn.em
""".strip().split()

facetSegDb=dict()
with open(facetsSegFile) as fp:
    for line in fp:
        (chrom,start,end,_,_,_,facetData)=line.strip().split()
        if facetData==".":
            continue
        start=int(start)+1
        key="%s:%d-%s" % (chrom,start,end)
        facetDict=dict()
        for (k,v) in zip(facetSegCol,facetData.split("|")):
            facetDict[k]=v
        (proj,tumor,normal)=facetDict["ID"].split("_s_")
        tumor="s_"+tumor
        normal="s_"+normal
        facetSegDb[(key,tumor,normal)]=facetDict

def computeCCFAndCopies(r,f,purity):
    if f["lcn"]=="NA" or f["tcn"]=="NA":
        return ("NA","NA")
    purity=float(purity)
    tcn=float(f["tcn"])
    lcn=float(f["lcn"])
    ns=float(r["t_alt_count"])
    nw=float(r["t_ref_count"])
    Pi=1-purity
    M=tcn-lcn
    r=M
    m=lcn
    allele_fraction=ns/(ns+nw)
    if r>0 and purity>0:
        frac=min((allele_fraction*(purity*(M+m)+2*Pi)/purity)/r,1)
    else:
        frac=1

    rSeq=xrange(1,int(M+1))
    frac1 = [purity * r / (purity * (M+m) + 2*Pi) for r in rSeq]

    pcopies = [(f ** ns) * ((1-f)**nw) for f in frac1]

    copies=max(zip(pcopies,rSeq))[1]

    return (frac,copies)

##############################################################################
##############################################################################

events=dict()
with open(origMAFFile) as fp:
    print fp.readline(),
    cin=csv.DictReader(fp,delimiter="\t")
    for r  in cin:
        if r["Reference_Allele"]!=r["Tumor_Seq_Allele1"]:
            alt=r["Tumor_Seq_Allele1"]
        elif r["Reference_Allele"]!=r["Tumor_Seq_Allele2"]:
            alt=r["Tumor_Seq_Allele2"]
        else:
            print >>sys.stderr, "Should never get here"
            print >>sys.stderr
            print >>sys.stderr, r
            print >>sys.stderr
            sys.exit()
        chrom=r["Chromosome"][3:]
        pos=r["Chromosome"]+":"+r["Start_Position"]+"-"+r["End_Position"]
        tag=pos+":"+r["Reference_Allele"]+":"+alt
        label=tag+"::"+r["Tumor_Sample_Barcode"]+":"+r["Matched_Norm_Sample_Barcode"]
        r["Chromosome"]=cvtChrom(chrom)
        r["POS"]=pos
        r["TAG"]=tag
        r["LABEL"]=label
        if pos in seqDb:
            r["TriNuc"]=seqDb[pos]
        else:
            r["TriNuc"]=""
        r["IMPACT_410"]="T" if pos in impact410 else "F"

        if r["t_depth"]=="":
            #print >>sys.stderr, label
            r["t_depth"]=str(int(r["t_alt_count"])+int(r["t_ref_count"]))
        r["t_var_freq"]=float(r["t_alt_count"])/float(r["t_depth"])

        if r["n_alt_count"]=="":
            r["n_var_freq"]=""
        else:
            if r["n_depth"]=="":
                r["n_depth"]=str(int(r["n_alt_count"])+int(r["n_ref_count"]))
            r["n_var_freq"]=float(r["n_alt_count"])/float(r["n_depth"])

        if pos in exacDb:
            r["ExAC_AC"]=exacDb[pos]["AC"]
            r["ExAC_AF"]=exacDb[pos]["AF"]
            r["ExAC_AN"]=exacDb[pos]["AN"]

        facetSampInfo=facetSampDb[(r["Tumor_Sample_Barcode"],r["Matched_Norm_Sample_Barcode"])]
        r["Purity"]=facetSampInfo["Purity"]
        r["Ploidy"]=facetSampInfo["Ploidy"]
        r["WGD"]="Yes" if float(facetSampInfo["dipt"]>2) else "No"

        fKey=(pos,r["Tumor_Sample_Barcode"],r["Matched_Norm_Sample_Barcode"])
        if fKey in facetSegDb:
            facetSegInfo=facetSegDb[(pos,r["Tumor_Sample_Barcode"],r["Matched_Norm_Sample_Barcode"])]
            r["seg.mean"]=facetSegInfo["cnlr.median"]
            r["cf"]=facetSegInfo["cf"]
            r["tcn"]=facetSegInfo["tcn"]
            r["lcn"]=facetSegInfo["lcn"]
            (est_frac,est_copies)=computeCCFAndCopies(r,facetSegInfo,float(facetSampInfo["Purity"]))
            r["est_frac"]=est_frac
            r["est_copies"]=est_copies
        else:
            print >>sys.stderr, fKey, "Missing in facets seg data"
            r["seg.mean"]="NA"
        events[label]=r

outFields=cin.fieldnames+["POS","TAG","LABEL","TriNuc","IMPACT_410","t_var_freq","n_var_freq",
                            "ExAC_AC","ExAC_AF","ExAC_AN",
                            "Purity","Ploidy","WGD",
                            "seg.mean","cf","tcn","lcn",
                            "est_frac","est_copies"]
cout=csv.DictWriter(sys.stdout,outFields,delimiter="\t")
cout.writeheader()
for ki in sorted(events):
    cout.writerow(events[ki])

