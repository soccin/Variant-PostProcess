~/opt/bin/convert *png facets__Proj_5615_C.pdf
Rscript --no-save ../v3/FACETS/facets2igv.R
mv IGV_* facets__Proj_5615_C.seg

(cat facets__*cncf.txt | head -1; cat facets__*cncf.txt | egrep -v "^ID") \
    >facets__Proj_5615_C__cval_300_cncf.txt

facets__Proj_5615_C.txt

