#!/usr/bin/env python2.7

"""normalizeInDels.py Normalize complex insertions/deletions in a MAF

At complex in/del events generate by Haplotype caller; e.g;

  chr1  198498325 . AATATAT A,AATATATAT
  chr7  123672456 . CGCTGCT C,CGCT

The longer event will get translated to a non-standard/non-minimal event

  chr1  198498325 198498331 ATATAT  ATATAT  ATATATAT
  chr7  123672457 123672462 GCTGCT  GCTGCT  GCT

While this appears to follow the MAF spec most programs do not parse this
event correctly.

normalizeInDels will take a TCGA formatted MAF (ie the column headers must match
the official TCGA convention) and for all INS or DEL events where the Ref/Alt is
a suffix of Alt/Ref (INS/DEL respectively) the program will normalize the
event to the minimal form (with the leftward convention).

So the above two events get translated to:

  chr1  198498325 198498326 - - AT
  chr7  123672457 123672459 GCT GCT -

Which most programs can parse.

Note if there is a complex event where the Ref and Alt are not suffixes of Alt/Ref
(not sure if this can happen) the program will throw an error and exit

"""

import sys
import csv

import argparse
parser=argparse.ArgumentParser()
parser.add_argument("maf0", help="Old maf file")
parser.add_argument("maf1", help="New maf file")
args=parser.parse_args()

def stripCommentsFromStream(input,output):
  '''stripCommentsFromStream
  Given an input file object remove any comment
  header lines (lines starting with "#") and
  write these lines verbatum to the output.
  Then pass back the remaining input lines
  '''

  line=input.next()
  while line.startswith("#"):
    print >>output, line,
    line=input.next()
  yield line # First non-comment line
  for line in input:
    yield line

with open(args.maf0, 'rb') as input:
  if args.maf1=="-":
    output=sys.stdout
  else:
    output=open(args.maf1,'w')
  cin=csv.DictReader(stripCommentsFromStream(input,output),delimiter="\t")
  cout=csv.DictWriter(output,cin.fieldnames,delimiter="\t")
  cout.writeheader()
  for r in cin:

    if r["Variant_Type"]=="INS" and r["Reference_Allele"]!="-":
      if r["Tumor_Seq_Allele2"].endswith(r["Reference_Allele"]):
        r["Tumor_Seq_Allele2"]=r["Tumor_Seq_Allele2"][:-len(r["Reference_Allele"])]
        if r["Tumor_Seq_Allele1"]==r["Reference_Allele"]:
          r["Tumor_Seq_Allele1"]="-"
        else:
          r["Tumor_Seq_Allele1"]=r["Tumor_Seq_Allele2"]
        r["Reference_Allele"]="-"
        r["End_Position"]=str(int(r["Start_Position"])+1)

      else:
        print >>sys.stderr, "normalizeInDels.py::Unknown complex insertion config",
        print >>sys.stderr, r["Chromosome"],r["Start_Position"],r["Reference_Allele"],r["Tumor_Seq_Allele2"]
        sys.exit(1)

    elif r["Variant_Type"]=="DEL" and r["Tumor_Seq_Allele2"]!="-":
      if r["Reference_Allele"].endswith(r["Tumor_Seq_Allele2"]):
        r["Reference_Allele"]=r["Reference_Allele"][:-len(r["Tumor_Seq_Allele2"])]
        if r["Tumor_Seq_Allele1"]==r["Tumor_Seq_Allele2"]:
          r["Tumor_Seq_Allele1"]="-"
        else:
          r["Tumor_Seq_Allele1"]=r["Reference_Allele"]
        r["Tumor_Seq_Allele2"]="-"
        r["End_Position"]=str(int(r["Start_Position"])+len(r["Reference_Allele"])-1)

      else:
        print >>sys.stderr, "normalizeInDels.py::Unknown complex deletion config",
        print >>sys.stderr, r["Chromosome"],r["Start_Position"],r["Reference_Allele"],r["Tumor_Seq_Allele2"]
        sys.exit(1)

    cout.writerow(r)
