#!/usr/bin/env python3

import sys

def read_fasta(fasta_file):
    """Read a FASTA file and return a dictionary of sequences."""
    sequences = {}
    current_id = None
    current_seq = []
    
    with open(fasta_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                if current_id:
                    sequences[current_id] = ''.join(current_seq)
                current_id = line[1:].split()[0]  # Get ID without '>'
                current_seq = []
            else:
                current_seq.append(line)
        
        if current_id:
            sequences[current_id] = ''.join(current_seq)
    
    return sequences

def read_bed(bed_file):
    """Read a BED file and return unique IDs from column 1."""
    unique_ids = set()
    
    with open(bed_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                fields = line.split('\t')
                unique_ids.add(fields[0])
    
    return unique_ids

def extract_sequences(fasta_file, bed_file, output_file=None):
    """Extract sequences from FASTA file based on BED file IDs."""
    sequences = read_fasta(fasta_file)
    unique_ids = read_bed(bed_file)
    
    output = sys.stdout if output_file is None else open(output_file, 'w')
    
    for seq_id in unique_ids:
        if seq_id in sequences:
            output.write(f'>{seq_id}\n{sequences[seq_id]}\n')
    
    if output_file:
        output.close()

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python fasta_xtractor.py <fasta_file> <bed_file> [output_file]")
        sys.exit(1)
    
    fasta_file = sys.argv[1]
    bed_file = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else None
    
    extract_sequences(fasta_file, bed_file, output_file)