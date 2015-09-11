# Variant-PostProcess (v1)

To use clone version to someplace on LUNA. Then to run

```bash
$CLONEDIR/bProcess.sh <PIPELINE_OUTPUT_DIR>
```

For example:

```bash
/home/socci/Code/Bin/PostProcessV1/bProcess.sh /ifs/res/seq/faginj/knaufj/Proj_05873_D/r_002
```

which should create if successful:

* ```Proj_05873_D___SOMATIC.vep.maf``` - Somatic MAF file annotated with VEP

* ```Proj_05873_D___FILLOUT.vep.maf``` - Global FillOut of events in Somatic MAF



