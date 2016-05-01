#!/usr/bin/env python2.7

import sys
import csv

cin=csv.DictReader(sys.stdin,delimiter="\t")
fields=cin.fieldnames+["COUNT_REF","COUNT_ALT"]
cout=csv.DictWriter(sys.stdout,fields,delimiter="\t")
cout.writeheader()
for rec in cin:
    if rec["GT"]!="0/0" and rec["GT"]!="./.":
        try:
            ad_ref=int(rec["AD_REF"])
            ad_alt=int(rec["AD_ALT"])
            depth=ad_ref+ad_alt
            if depth >= 10 and ad_alt > 2:
                cout.writerow(rec)
        except:
            print >>sys.stderr, "-"*80
            print >>sys.stderr, rec
            print >>sys.stderr


"""
GENE SAMPLE CHROM POS REF ALT
FILTER QUAL ID GT GQ ALT_FREQ
AD_REF AD_ALT CALLER
HC_AC HC_AF HC_AN
HC_BaseQRankSum HC_ClippingRankSum HC_DB
HC_DP HC_DS HC_END
HC_FS HC_HaplotypeScore HC_InbreedingCoeff
HC_MLEAC HC_MLEAF HC_MQ
HC_MQ0 HC_MQRankSum HC_NEGATIVE_TRAIN_SITE
HC_POSITIVE_TRAIN_SITE HC_QD HC_ReadPosRankSum
HC_VQSLOD HC_culprit HC_set
HC_AB HC_PL Mutation_Status
Validation_Status
"""
