#!/opt/common/CentOS_6-dev/R/R-3.2.2/bin/Rscript --no-save --vanilla

require(stringr)

###############################################################################
len<-function(x){length(x)}

getMAFHeader<-function(fname){

    header=readLines(fname,100)
    colNameRow=grep("^Hugo_Symbol",header)
    if(len(colNameRow)==0){
        cat("\n\nFATAL ERROR: INVALID MAF HEADER\n\n")
        stop("collapseNormalizedMAF.R::L-9")
    }

    return(header[1:(colNameRow-1)])

}

###############################################################################

cArgs=commandArgs(trailing=T)

#
# This code will parse command line args in the form of
#    KEY=VAL
# and sets
#    args[[KEY]]=VAL
#

# Set defaults first

args=list(MAFFILE=NULL,RevisionTAG="unknown")
parseArgs=str_match(cArgs,"(.*)=(.*)")
dummy=apply(parseArgs,1,function(x){args[[str_trim(x[2])]]<<-str_trim(x[3])})

if(is.null(args$MAFFILE)) {
    cat("\n\tusage: collapseNormalizedMAF.R MAFFILE=MAFFILE\n\n")
    quit()
}

require(data.table)

mafHeader=getMAFHeader(args$MAFFILE)

TCGA_COLS=1:34
maf=fread(args$MAFFILE)

#
# Get rid of any column that is
#   * all NA's
#   * not a TCGA Column (1-34)
#

emptyColumns=which(apply(maf,2,function(x){all(is.na(x))}))

mafC=maf[,-setdiff(emptyColumns,TCGA_COLS),with=F]


notExonicVariantClasses=c("Intron", "5'UTR", "3'UTR", "5'Flank", "3'Flank", "IGR")

## HGVSc        : HGVS coding sequence name
## HGVSp        : HGVS protein sequence name

mafC$MARK_CODING_CHANGE=""

mafC[
        !(HGVSp=="" & HGVSp_Short=="" | HGVSp=="p.=")
        & !(Variant_Classification %in% notExonicVariantClasses) ]$MARK_CODING_CHANGE = "Y"

#
# Fix the order of events
#   * Rational Chromosome 1:22 (or19), X, Y, (M|MT)
#   * Start Position

reorder=order(factor(mafC$Chromosome,levels=c(1:22,"X","Y","M","MT")),mafC$Start_Position)
mafC=mafC[reorder,]

OUTMAFFILE=gsub(".txt$","_PPv5.txt",args$MAFFILE)

write(mafHeader,OUTMAFFILE)
versionString=paste0("#Variant-PostProcess:collapseNormalizedMAF:Version[",args$RevisionTAG,"]")
#write(paste0("#DS: ",date()),OUTMAFFILE,append=T)
write(versionString,OUTMAFFILE,append=T)


write.table(mafC,file=OUTMAFFILE,row.names=F,na="",append=T,
    sep = "\t", quote = FALSE, col.names = T
    )


