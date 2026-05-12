#!/usr/bin/env python3
"""
Extract mapped read counts per reference from a BAM file.

This script counts the number of mapped reads for each reference sequence
in a BAM file and outputs a TSV file with references that meet a minimum
read count threshold.

Usage:
    python bam_read_counter.py -b input.bam -o output.tsv -m 10
"""

import argparse
import sys
from collections import defaultdict

try:
    import pysam
except ImportError:
    print("Error: pysam is required. Install it with: pip install pysam", file=sys.stderr)
    sys.exit(1)


def count_reads_per_reference(bam_file):
    """
    Count the number of mapped reads for each reference in a BAM file.
    
    Args:
        bam_file (str): Path to the BAM file
        
    Returns:
        dict: Dictionary with reference names as keys and read counts as values
    """
    read_counts = defaultdict(int)
    
    try:
        bam = pysam.AlignmentFile(bam_file, "rb")
    except Exception as e:
        print(f"Error opening BAM file: {e}", file=sys.stderr)
        sys.exit(1)
    
    try:
        for read in bam:
            # Only count mapped reads (not unmapped)
            if not read.is_unmapped:
                ref_name = bam.get_reference_name(read.reference_id)
                read_counts[ref_name] += 1
            else:
                read_counts["unmapped"] += 1

    except Exception as e:
        print(f"Error reading BAM file: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        bam.close()
    
    return dict(read_counts)


def main():
    parser = argparse.ArgumentParser(
        description="Extract mapped read counts per reference from a BAM file",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -b input.bam -o output.tsv -m 10
  %(prog)s -b mapped.bam -o refs.tsv --min-reads 100
        """
    )
    
    parser.add_argument(
        "-b", "--bam",
        required=True,
        help="Path to input BAM file"
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        help="Path to output TSV file"
    )
    parser.add_argument(
        "-m", "--min-reads",
        type=int,
        default=0,
        help="Minimum number of reads required to include a reference (default: 0)"
    )
    
    args = parser.parse_args()
    
    # Count reads per reference
    print(f"Processing BAM file: {args.bam}", file=sys.stderr)
    read_counts = count_reads_per_reference(args.bam)
    
    if not read_counts:
        print("Warning: No mapped reads found in BAM file", file=sys.stderr)
    
    # Filter by minimum read count and sort by read count (descending)
    filtered_refs = [
        (ref, count) for ref, count in read_counts.items()
        if count >= args.min_reads
    ]
    filtered_refs.sort(key=lambda x: x[1], reverse=True)
    
    # Write to TSV file
    if read_counts:
        try:
            with open(args.output, "w") as f:
                f.write("reference\treads_mapped\n")
                for ref_name, count in filtered_refs:
                    f.write(f"{ref_name}\t{count}\n")
        except Exception as e:
            print(f"Error writing output file: {e}", file=sys.stderr)
            sys.exit(1)
    
    print(f"Wrote {len(filtered_refs)} references to {args.output}", file=sys.stderr)
    print(f"Total mapped reads: {sum(count for _, count in filtered_refs)}", file=sys.stderr)


if __name__ == "__main__":
    main()
