# Variant-PostProcess (v3)

## TERMINAL: This version does not work properly. 

* In/del's not left aligned always

* Disagrees with VarDict; (see files in `testing`)

This version fixes the problem with overlapping IN/DEL's in Haplotype VCF. It first fixes
the Haplotype VCF and then uses the BIC post routines.

* `FixMultiInDel/fixMultiInDel.sh`

* `variants_pipeline/haploTect_merge.pl`

* FACETS_MERGE

