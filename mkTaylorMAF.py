#!/usr/bin/env python2.7

import sys
import csv

def cvtChrom(x):
    if x.isdigit():
        return int(x)
    else:
        return x

seqDataFile=sys.argv[1]
impact410File=sys.argv[2]
origMAFFile=sys.argv[3]

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
            r["t_depth"]=str(int(r["t_alt_count"])+int(r["t_ref_count"]))
        r["t_var_freq"]=float(r["t_alt_count"])/float(r["t_depth"])

        if r["n_alt_count"]=="":
            r["n_var_freq"]=""
        else:
            if r["n_depth"]=="":
                r["n_depth"]=str(int(r["n_alt_count"])+int(r["n_ref_count"]))
            r["n_var_freq"]=float(r["n_alt_count"])/float(r["n_depth"])

        events[label]=r

outFields=cin.fieldnames+["POS","TAG","LABEL","TriNuc","IMPACT_410","t_var_freq","n_var_freq"]
cout=csv.DictWriter(sys.stdout,outFields,delimiter="\t")
cout.writeheader()
for ki in sorted(events):
    cout.writerow(events[ki])

