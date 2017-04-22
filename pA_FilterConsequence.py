#!/usr/bin/env python2.7

from PAWK import PAWK
import sys

consequenceDb=set("""
coding_sequence_variant
frameshift_variant
inframe_deletion
inframe_insertion
missense_variant
splice_acceptor_variant
splice_donor_variant
start_lost
stop_gained
stop_lost
""".strip().split())

def readWriteHeader(fp,newHeaderLines=[]):
    for line in fp:
        if line.startswith("#"):
            print line,
        else:
            break

    for hi in newHeaderLines:
        print hi

    yield line
    for line in fp:
        yield line


inStream=readWriteHeader(sys.stdin,
    ["#CBE:PostProcessV2(mouse) Filter Consequence (noUTR)"]
    )

for rec in PAWK(inStream):
    if rec.Consequence in consequenceDb:
        rec.write()

