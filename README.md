# Variant-PostProcess (v3)

## JUNO Version (2022-06-02)

Uses local SDIR/opt for old version of R (3.3.1); See opt.manifest for files if you need to recreate

This version does not work properly. But for now this is the best solution so currently being used in production.

* Disagrees with VarDict; (see files in `testing`)

This version fixes the problem with overlapping IN/DEL's in Haplotype VCF. It first fixes
the Haplotype VCF and then uses the BIC post routines.

* `FixMultiInDel/fixMultiInDel.sh`

* `variants_pipeline/haploTect_merge.pl`

* FACETS_MERGE

