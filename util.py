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
