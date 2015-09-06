#!/usr/bin/env python2.7

from PAWK import PAWK
import sys

consequenceDb=set("""
frameshift_variant
inframe_deletion
inframe_insertion
missense_variant
splice_acceptor_variant
splice_donor_variant
splice_region_variant
stop_gained
""".strip().split())


print sys.stdin.readline(),
print "#PostProcessV1 Filter Consequence (noUTR)"
for rec in PAWK(sys.stdin):
    if rec.Consequence in consequenceDb:
        rec.write()

