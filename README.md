# Variant-PostProcess (v5)

## Strictly Post MAF version

This version assumes the input MAF is a properly merged MAF with all events present (all rows are present) and intact. PostProcess V5 will _only add_ columns to the MAF that either

* Add annotation

* Add filtering flags (which are kind of annotation)

* Join other info: like facets (really more annotation)

Columns may be removed but this is highly undesirable and should be avoided if possible. 

