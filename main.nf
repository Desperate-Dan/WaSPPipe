#!/usr/bin/env nextflow

// Get the modules we need
include { readFilter } from './modules/consensus_generation.nf'

workflow consensus_wf {
    // Define the input channels
    inFiles_ch = Channel.fromFilePairs("${params.fastq}/barcode")
}