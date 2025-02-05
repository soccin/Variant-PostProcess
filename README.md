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

## Methods

### Illumina (HiSeq) Exome Variant Detection Pipeline

The data processing pipeline for detecting variants in Illumina HiSeq data follows a standardized workflow using version-controlled software tools. Initial processing begins with adapter trimming of FASTQ files using cutadapt (v1.9.1) to remove standard Illumina 5' and 3' adapter sequences. The trimmed reads are then mapped to the B37 reference genome from the Broad GATK resource bundle using BWA-MEM (v0.7.12).

Post-alignment processing includes sorting of SAM files and addition of read group tags using PICARD tools (v1.124). The read group information includes sample identifiers, sequencing library identifiers, and Illumina platform information. The sorted BAM files are then processed with PICARD MarkDuplicates to identify PCR duplicates.

Following duplicate marking, the BAM files are processed according to GATK (v3.4-0) best practices version 3 for tumor-normal pairs. This includes local realignment using ABRA (v2.17) with default parameters, followed by base quality score recalibration using BaseQRecalibrator with known variants from the Broad GATK B37 resource bundle, including dbSNP v138.

Somatic variant calling is performed using muTect (v1.1.7) with default parameters for SNV detection, while somatic indels are identified using GATK HaplotypeCaller with subsequent custom post-processing. A final "fill-out" step computes the complete read depth information at each variant position across all samples using the realigned BAMs. This step applies quality filters requiring mapping quality ≥ 20 and base quality ≥ 0, with no filtering for proper read pairing.

All analyses were performed using a standardized computational environment managed through Singularity (v2.6.0). The complete pipeline source code, including all post-processing scripts, is available at https://github.com/soccin/BIC-variants_pipeline and https://github.com/soccin/Variant-PostProcess. Additional software versions used in the pipeline include Perl (v5.22.0), Samtools (v1.2), VCF2MAF (v1.6.21), and VEP (v102).
