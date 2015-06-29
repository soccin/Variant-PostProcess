#!/usr/bin/env python2.7

import TCGA_MAF
import sys
import csv

class Bunch:
    def __init__(self,dictRec):
        self.__dict__.update(dictRec)
    def __str__(self):
        return str(self.__dict__)

def bunchStream(cin):
    for rec in cin:
        yield Bunch(rec)

def getALT(s):
    if(args.verbose and s.GT == "0/0"):
      return s.ALT
    alts=s.ALT.split(";")
    altGT=list(set([int(x) for x in s.GT.split("/") if x !="0"]))
    altPicked=alts[altGT[0]-1]
 
    # If there are more than 1 alternative alleles, 
    # you're going to make sure that there is no extra anchored bp things
    # So I will compare each bp from the start of alt and ref, and stop
    # when they don't match.
    if(len(alts) > 1):
        numDeleted=0
        print "POS: " + s.CHROM + ":" + s.POS
        print "REF Before: " + s.REF
        print "ALT OPTIONS: " + s.ALT
        print "ALT Picked: " + altPicked 
        for i in range(min(len(altPicked), len(s.REF))):
            if s.REF[0] == altPicked[0]:
		s.REF=s.REF[1:]
                altPicked=altPicked[1:]
		numDeleted += 1
            else:
                break

        for i in range(min(len(altPicked), len(s.REF))):
            if s.REF[-1] == altPicked[-1]:
                s.REF=s.REF[:-1]
                altPicked=altPicked[:-1]
            else:
                break

        # if indel, one of the alleles will be -
        if len(s.REF)==0:
            s.REF="-"
        elif len(altPicked) == 0:
            altPicked="-"

        s.POS = str(int(s.POS) + numDeleted)
        print "NEW POS: " + s.CHROM + ":" + s.POS + "\nREF After: " + s.REF + "\nALT After: " + altPicked + "\n\n" 
         
    s.ALT=altPicked

    if s.REF == s.ALT:
        print "ERROR: ref and alt are the same. There is no variant!!"
        sys.exit()

    return s

def getVarType(s):
    alt=s.ALT.replace("-","")
    ref=s.REF.replace("-","")
    if len(ref)==len(alt):
        if len(ref)==1:
            return "SNP"
        elif len(ref)==2:
            return "DNP"
        elif len(ref)==3:
            return "TNP"
        else:
            return "ONP"
    elif len(ref)>len(alt):
        return "DEL"
    else:
        return "INS"

import argparse
parser=argparse.ArgumentParser()
parser.add_argument("GENOME",help="Genome build, must be specified")
parser.add_argument("maf0", help="Old maf file")
parser.add_argument("maf1", help="New maf file")
parser.add_argument('-v','--verbose',action='store_true',help='If specified, create a verbose maf that includes vcf entries with no reads')
args=parser.parse_args()

NEWFLDS="FILTER QUAL GT GQ ALT_FREQ NORM_GT NORM_GQ NORM_ALT_FREQ".split()
with open(args.maf0) as input:
  header = input.readline().strip().split()
  if "t_ref_count" in header:
    NEWFLDS = "FILTER QUAL GT GQ ALT_FREQ t_ref_count t_alt_count NORM_GT NORM_GQ NORM_ALT_FREQ n_ref_count n_alt_count".split()
  elif("HC_SNPEFF_EFFECT" in header or "HC_SNPEFF_FUNCTIONAL_CLASS" in header or "HC_SNPEFF_GENE_NAME"):
    NEWFLDS="FILTER QUAL GT GQ ALT_FREQ NORM_GT NORM_GQ NORM_ALT_FREQ HC_SNPEFF_AMINO_ACID_CHANGE HC_SNPEFF_CODON_CHANGE HC_SNPEFF_EFFECT HC_SNPEFF_EXON_ID HC_SNPEFF_FUNCTIONAL_CLASS HC_SNPEFF_GENE_BIOTYPE HC_SNPEFF_GENE_NAME HC_SNPEFF_IMPACT HC_SNPEFF_TRANSCRIPT_ID".split()


class TCGA_MAF_Ext(TCGA_MAF.TCGA_MAF):
    pass
TCGA_MAF_Ext.addFields(NEWFLDS)
with open(args.maf1, 'w') as output:
  with open(args.maf0, 'rb') as input:
    output.write(TCGA_MAF_Ext.header() + "\n")
    dreader = csv.DictReader(input, delimiter="\t")
    for rec in bunchStream(dreader):
      if not args.verbose and ("0/0" in rec.GT or "./." in rec.GT):
        sys.stderr.write("Skipping:" +  str(rec) +  ". There is 0 coverage\n")
        continue
      matchedNormSampleBarcode=rec.NORM_SAMPLE if hasattr(rec, "NORM_SAMPLE") else "REF."+args.GENOME
      rec = getALT(rec)
      maf=TCGA_MAF_Ext(
        Chromosome=rec.CHROM,
        Start_Position=rec.POS,
        End_Position=int(rec.POS)+len(rec.REF)-1,
        Reference_Allele=rec.REF,
        Tumor_Seq_Allele1=rec.REF,
        Tumor_Seq_Allele2=rec.ALT,
        dbSNP_RS=rec.ID,
        Tumor_Sample_Barcode=rec.SAMPLE,
        Matched_Norm_Sample_Barcode=matchedNormSampleBarcode,
        Variant_Type=getVarType(rec),
        Hugo_Symbol=rec.GENE,
        t_ref_count=rec.AD_REF,
        t_alt_count=rec.AD_ALT,
        Caller=rec.CALLER
      )

      #
      # If GT is NOT 0/x, Make Allele1 equal the alt allele
      # corresponding to it.
      # This is still WRONG because if you 1/2 you would want both alelles
      # But since you are supposed to have as little as possible extra alleles
      # It will get very complicated in the get alt script
      #
      if rec.GT.split("/")[0] != '0':
          maf.Tumor_Seq_Allele1=rec.ALT

      #
      # Fix mutation signature for INS/DEL
      # to confirm to TCGA standard
      #

      '''
      if maf.Variant_Type=="DEL":
        maf.Start_Position=str(int(maf.Start_Position)+1)
        maf.Reference_Allele=maf.Reference_Allele[1:]
        if len(maf.Tumor_Seq_Allele1)>1:
          maf.Tumor_Seq_Allele1=maf.Tumor_Seq_Allele1[1:]
        else:
          maf.Tumor_Seq_Allele1="-"
      elif maf.Variant_Type=="INS":
        maf.End_Position=str(int(maf.End_Position)+1)
        maf.Reference_Allele="-"
        maf.Tumor_Seq_Allele1=maf.Tumor_Seq_Allele1[1:]
      '''
      if maf.Variant_Type=="INS":
          maf.Start_Position=str(int(maf.Start_Position)-1)

      if hasattr(rec, "NORM_AD_REF"):
        maf.n_ref_count=rec.NORM_AD_REF
        maf.n_alt_count=rec.NORM_AD_ALT
      maf.NCBI_Build=args.GENOME
      for fld in NEWFLDS:
         attr=getattr(rec,fld) if hasattr(rec,fld) else ""
         setattr(maf,fld,attr)
      output.write(str(maf) + "\n")
