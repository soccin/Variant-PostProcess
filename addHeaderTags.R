#!/opt/common/CentOS_6-dev/R/R-3.2.2/bin/Rscript --no-save --vanilla

require(stringr)

###############################################################################
len<-function(x){length(x)}

getMAFHeader<-function(fname){

    header=readLines(fname,100)
    colNameRow=grep("^Hugo_Symbol",header)
    if(len(colNameRow)==0){
        cat("\n\nFATAL ERROR: INVALID MAF HEADER\n\n")
        stop("addHeaderTags.R::L-14")
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

args=list(IN=NULL,RevisionTAG="unknown",OUT=NULL)
parseArgs=str_match(cArgs,"(.*)=(.*)")
dummy=apply(parseArgs,1,function(x){args[[str_trim(x[2])]]<<-str_trim(x[3])})

if(is.null(args$IN)) {
    cat("\n\tusage: addHeaderTags.R IN=input.maf [OUT=output.maf]\n")
    cat("\t  default OUT=input_PPv5.txt\n\n")
    quit()
}

require(data.table)

mafHeader=getMAFHeader(args$IN)

maf=fread(args$IN)

if(is.null(args$OUT)) {
    OUTMAFFILE=gsub("(.maf|.txt)$","_PPv5.txt",args$IN)
} else {
    OUTMAFFILE=args$OUT
}


write(mafHeader,OUTMAFFILE)
write(paste0("#DS: ",date()),OUTMAFFILE,append=T)
versionString=paste0("#Variant-PostProcess::Version[",args$RevisionTAG,"]")
write(versionString,OUTMAFFILE,append=T)

write.table(maf,file=OUTMAFFILE,row.names=F,na="",append=T,
    sep = "\t", quote = FALSE, col.names = T
    )


