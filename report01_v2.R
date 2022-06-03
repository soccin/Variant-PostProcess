require(tidyverse)
require(fs)
require(openxlsx)

args=commandArgs(trailing=T)

if(len(args)<1) {
    stop("FATAL ERROR: usage report01_v2.R PIPELINEDIR")
}

pipeline=args[1]

coverageFile=pipeline %>%
    dir_ls(regex="metrics") %>%
    dir_ls(regex="HsMetrics")

if(len(coverageFile)>0) {

    try({
        coverage = coverageFile %>%
            read_tsv %>%
            select(SAMPLE,MEAN_TARGET_COVERAGE)
    })

}

parseFACETSOut<-function(fi) {
    dat=readLines(fi) %>% gsub("^# ","",.) %>% grep(" = ",.,value=T) %>% map(strsplit," = ")
    flds=map(dat,~.[[1]][1]) %>% unlist
    vals=map(dat,~gsub(" ","",.[[1]][2])) %>% unlist
    rec=vals
    names(rec)=flds
    rec=rec[unique(names(rec))]
    as_tibble(as.list(rec))
}

facetsOutFiles=pipeline %>%
    dir_ls(regex="variants") %>%
    dir_ls(regex="copyNumber") %>%
    dir_ls(recur=T,regex="\\.txt$") %>%
    grep(".(qc|level|mapping).txt",.,value=T,invert=T)

facets=map(facetsOutFiles,read_tsv,col_types = cols(.default = "c"),progress=F) %>%
    bind_rows %>%
    filter(run_type=="purity") %>%
    select(SAMPLE=sample,Purity=purity,Ploidy=ploidy) %>%
    mutate(SAMPLE=gsub(".*_s_","s_",SAMPLE))

if(exists("coverage")) {
    report01=full_join(coverage,facets)
} else {
    report01=facets
}

projNo=grep("Proj_",strsplit(args,"/")[[1]],value=T) %>% gsub("Proj","proj",.)

write.xlsx(report01,cc(projNo,"_Report01.xlsx"))
