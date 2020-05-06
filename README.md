# Variant-PostProcess (v3)

## FINAL LUNA Version (removed -We args to deal with final config)

This version does not work properly. But for now this is the best solution so currently being used in production.

* Disagrees with VarDict; (see files in `testing`)

This version fixes the problem with overlapping IN/DEL's in Haplotype VCF. It first fixes
the Haplotype VCF and then uses the BIC post routines.

* `FixMultiInDel/fixMultiInDel.sh`

* `variants_pipeline/haploTect_merge.pl`

* FACETS_MERGE

