#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
VARIANTSPIPEDIR=/home/socci/Code/Pipelines/CBE/Variant/variants_pipeline
BEDTOOLS=/opt/common/CentOS_6/bedtools/bedtools-2.22.0/bin/bedtools
VEPPATH=/opt/common/CentOS_6/vep/v79
EXACDB=/ifs/work/socci/Depot/Pipelines/Variant/PostProcess/db/ExAC.r0.3.sites.pass.minus_somatic.vcf.gz


if [ $# -ne 1 ]; then
	echo "usage: addExACtoMAF.sh MAF"
	exit
fi

#GENOME=/common/data/assemblies/H.sapiens/hg19/hg19.fasta
GENOME=/ifs/work/socci/Depot/Genomes/H.sapiens/b37/Homo_sapiens_assembly19.fasta
MAF=$1

TDIR=_scratch/$(uuidgen)
mkdir -p $TDIR

ln -s $GENOME $TDIR/genome.fasta
ln -s ${GENOME}.fai $TDIR/genome.fasta.fai

$SDIR/maf2vcfSimple.sh $TDIR $MAF >$TDIR/maf0.vcf
cat $TDIR/maf0.vcf | sed 's/^chr//' > $TDIR/maf1.vcf
$SDIR/bin/bgzip $TDIR/maf1.vcf
$SDIR/bin/tabix -p vcf $TDIR/maf1.vcf.gz
/opt/common/CentOS_6/bcftools/bcftools-1.2/bin/bcftools \
    annotate --annotations $EXACDB \
    --columns AC,AN,AF --output-type v \
    --output $TDIR/maf1.exac.vcf $TDIR/maf1.vcf.gz

$SDIR/joinExAC.py $TDIR/maf1.exac.vcf $MAF >${MAF/.maf/}.exac.maf

rm -rf $TDIR
