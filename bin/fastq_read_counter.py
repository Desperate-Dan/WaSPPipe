#!/usr/bin/env python3
"""Count reads in a (gzipped) FASTQ file and print the count to stdout.

Usage:
    python3 bin/fastq_read_counter.py reads.fastq.gz
    cat reads.fastq.gz | python3 bin/fastq_read_counter.py -
"""
from __future__ import annotations

import argparse
import gzip
import sys


def open_maybe_gz(path: str):
    if path == '-':
        # read from stdin (assume it's already decompressed if necessary)
        return sys.stdin
    if path.endswith('.gz'):
        return gzip.open(path, 'rt')
    return open(path, 'rt')


def count_reads(path: str) -> int:
    with open_maybe_gz(path) as fh:
        lines = 0
        for _ in fh:
            lines += 1
    reads = lines // 4
    if lines % 4 != 0:
        print(
            f"Warning: total lines ({lines}) not divisible by 4; "
            f"reporting {reads} full reads",
            file=sys.stderr,
        )
    return reads


def main() -> None:
    p = argparse.ArgumentParser(description="Count reads in a FASTQ/FASTQ.GZ file")
    p.add_argument('-s', '--sample', help='Sample ID to prepend to output')
    p.add_argument('-c', '--condition', help='Condition to prepend to output')
    p.add_argument('fastq', help='Path to FASTQ or - to read from stdin')
    args = p.parse_args()

    try:
        reads = count_reads(args.fastq)
    except Exception as e:
        print(f"Error reading file: {e}", file=sys.stderr)
        sys.exit(2)

    if args.sample:
        if args.condition:
            print(f"{args.sample},{reads},{args.condition}")
        else:
            print(f"{args.sample},{reads}")
    else:
        print(reads)


if __name__ == '__main__':
    main()
