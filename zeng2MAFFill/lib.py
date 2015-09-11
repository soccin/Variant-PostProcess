import VEP_MAF

class Bunch:
    def __init__(self,dictRec):
        self.__dict__.update(dictRec)
    def __str__(self):
        return str(self.__dict__)

def bunchStream(cin):
    for rec in cin:
        yield Bunch(rec)

def getVarType(s):
    if len(s.Ref)==len(s.Alt):
        if len(s.Ref)==1:
            return "SNP"
        elif len(s.Ref)==2:
            return "DNP"
        elif len(s.Ref)==3:
            return "TNP"
        else:
            return "ONP"
    elif len(s.Ref)>len(s.Alt):
        return "DEL"
    else:
        return "INS"

def getEventSig(maf):
    return (maf.Chromosome,maf.Start_Position,maf.Reference_Allele,maf.Tumor_Seq_Allele1)

def fillSampleMAFFields(maf,si,ei,eventDb,pairs):
    maf.Tumor_Sample_Barcode=si
    matchedNormal=pairs[si]
    maf.Matched_Norm_Sample_Barcode= matchedNormal
    maf.t_ref_count=eventDb[ei][si]["RD"]
    maf.t_alt_count=eventDb[ei][si]["AD"]
    maf.n_ref_count=eventDb[ei][matchedNormal]["RD"]
    maf.n_alt_count=eventDb[ei][matchedNormal]["AD"]
    maf.Caller="mutect"
    return maf

class VEP_MAF_Ext(VEP_MAF.VEP_MAF):
    pass

