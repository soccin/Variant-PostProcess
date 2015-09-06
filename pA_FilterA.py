#!/usr/bin/env python2.7

from PAWK import PAWK
import sys

def cvt2int(s):
    if s=="":
        return 0
    else:
        return int(s)

def cvt2float(s):
    if s=="":
        return 0.0
    else:
        return float(s)

print sys.stdin.readline(),
print "#PostProcessV1 FilterA"
for rec in PAWK(sys.stdin):
    if rec.t_alt_count=="":
        continue
    if rec.GMAF!="":
        gmafDat=dict([(k,float(v)) for k,v in [x.split(":") for x in rec.GMAF.split(",")]])
        if rec.Tumor_Seq_Allele2 in gmafDat and gmafDat[rec.Tumor_Seq_Allele2]>0.002:
            print >>sys.stderr, "GMAF Filter", rec.GMAF, rec.Chromosome, rec.Start_Position, rec.Reference_Allele, rec.Tumor_Seq_Allele2
            continue
        if cvt2int(rec.ExAC_AC)>=4 or cvt2float(rec.ExAC_AF)>=0.01:
            print >>sys.stderr, "ExAC Filter", rec.ExAC_AC, rec.ExAC_AF, rec.Chromosome,
            print >>sys.stderr, rec.Start_Position
            continue
    rec.write()

'''
Hugo_Symbol Entrez_Gene_Id Center NCBI_Build Chromosome
Start_Position End_Position Strand Variant_Classification Variant_Type
Reference_Allele Tumor_Seq_Allele1 Tumor_Seq_Allele2 dbSNP_RS dbSNP_Val_Status
Tumor_Sample_Barcode Matched_Norm_Sample_Barcode Match_Norm_Seq_Allele1 Match_Norm_Seq_Allele2 Tumor_Validation_Allele1
Tumor_Validation_Allele2 Match_Norm_Validation_Allele1 Match_Norm_Validation_Allele2 Verification_Status Validation_Status
Mutation_Status Sequencing_Phase Sequence_Source Validation_Method Score
BAM_File Sequencer Tumor_Sample_UUID Matched_Norm_Sample_UUID HGVSc
HGVSp HGVSp_Short Transcript_ID Exon_Number t_depth
t_ref_count t_alt_count n_depth n_ref_count n_alt_count
all_effects Allele Gene Feature Feature_type
Consequence cDNA_position CDS_position Protein_position Amino_acids
Codons Existing_variation ALLELE_NUM DISTANCE STRAND
SYMBOL SYMBOL_SOURCE HGNC_ID BIOTYPE CANONICAL
CCDS ENSP SWISSPROT TREMBL UNIPARC
RefSeq SIFT PolyPhen EXON INTRON
DOMAINS GMAF AFR_MAF AMR_MAF ASN_MAF
EAS_MAF EUR_MAF SAS_MAF AA_MAF EA_MAF
CLIN_SIG SOMATIC PUBMED MOTIF_NAME MOTIF_POS
HIGH_INF_POS MOTIF_SCORE_CHANGE IMPACT PICK VARIANT_CLASS
TSL HGVS_OFFSET PHENO
'''
