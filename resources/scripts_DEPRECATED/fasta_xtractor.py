#!/usr/bin/env python3
# This script takes in a FASTA file and a BED file, extracts the sequences from the FASTA file that correspond to the IDs in the BED file, and writes them to individual FASTA files named after the sample ID and sequence ID. 
# If an output file name is provided, it will write all extracted sequences to a single FASTA file instead.

import argparse
import sys

def read_fasta(fasta_file):
    #Read a FASTA file and return a dictionary of sequences.
    sequences = {}
    header_details = {}
    current_id = None
    current_seq = []
    
    with open(fasta_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                if current_id:
                    sequences[current_id] = ''.join(current_seq) 
                current_id = line[1:].split()[0]  # Get ID without '>'
                header_details[current_id] = ' '.join(line[1:].split()[1:])
                current_seq = []
            else:
                current_seq.append(line)
        
        if current_id:
            sequences[current_id] = ''.join(current_seq)
    
    return sequences, header_details

def read_bed(bed_file):
    #Read a BED file and return unique IDs from column 1.
    unique_ids = {}
    unique_ids_read_counts = {}
    
    with open(bed_file, 'r') as f:
        for line in f:
            if line.startswith('reference'):
                continue
            if line.startswith("unclassified"):
                continue
            line = line.strip()
            if line:
                fields = line.split('\t')
                if args.top_only:
                    unique_ids_read_counts[fields[0]] = int(fields[1])
                    top_hit = max(unique_ids_read_counts, key=unique_ids_read_counts.get)
                    unique_ids[top_hit] = unique_ids_read_counts[top_hit]

                else:
                    unique_ids[fields[0]] = True
    return unique_ids

def extract_sequences(fasta_file, bed_file, sample_ID, output_file):
    #Extract sequences from FASTA file based on BED file IDs.
    sequences, header_details = read_fasta(fasta_file)
    unique_ids = read_bed(bed_file)
    counter = 0

    for seq_id in unique_ids:
        counter += 1
        if sample_ID:
            fasta_ID = f'{sample_ID}_{seq_id}'
        else:
            fasta_ID = f'{seq_id}'

        if not output_file:
            with open(f"{fasta_ID}.fasta", 'w') as output:
                if seq_id in sequences:
                    output.write(f'>{fasta_ID} {header_details[seq_id]}\n{sequences[seq_id]}\n')
        else:
            with open(f"{output_file}_{seq_id}.fasta", 'w') as output:
                if seq_id in sequences:
                    output.write(f'>{fasta_ID} {header_details[seq_id]}\n{sequences[seq_id]}\n')
            
if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Extract sequences from a FASTA file based on IDs in a BED file",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -f reference.fasta -b regions.bed -s sample1
  %(prog)s -f reference.fasta -b regions.bed -s sample1 -o combined_output
        """
    )
    
    parser.add_argument(
        "-f", "--fasta",
        required=True,
        help="Path to input FASTA file"
    )
    parser.add_argument(
        "-b", "--bed",
        required=True,
        help="Path to input BED file"
    )
    parser.add_argument(
        "-s", "--sample-id",
        help="Sample ID to prepend to sequence names"
    )
    parser.add_argument(
        "-o", "--output",
        help="Output file name (without extension). If not provided, creates individual files per sequence"
    )
    parser.add_argument(
        "--top_only",
        action='store_true',
        help="If set, only the sequence with the highest read count will be extracted and written to the output file"
    )
    
    args = parser.parse_args()
    
    extract_sequences(args.fasta, args.bed, args.sample_id, args.output)