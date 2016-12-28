# Variant-PostProcess (v4)

Second attempt to fix the problem with complex indel's in Haplotype caller. 
This version fixes the problem by recalling with VarDict which does pairwise
calling so there are no *extra* events. 

Flowchart:

* run BIC:variant_pipeline/haploTect_merge.pl on a _zero-ed_ out 
haplotype VCF to get just the MuTect Events.

* get locations of putative indels from haplotype (create bed) and 
run VarDict on all pairs.

	* Post process VarDict vcf's with DMP filter_vardict
	
	* convert to maf's with vcf2maf

* Merge MAF's from MuTect and VarDict

* do FACETS_MERGE

