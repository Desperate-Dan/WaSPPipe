#!/usr/bin/env nextflow

// Get the modules we need
include { readFilter } from './modules/consensus_generation.nf'

//These lines for fastq dir parsing are taken from rmcolq's workflow https://github.com/rmcolq/pantheon
EXTENSIONS = ["fastq", "fastq.gz", "fq", "fq.gz"]

ArrayList get_fq_files_in_dir(Path dir) {
    return EXTENSIONS.collect { file(dir.resolve("*.$it"), type: "file") } .flatten()
}

workflow consensus_wf {
    // Define the input channels
    // These lines for fastq dir parsing are taken from rmcolq's workflow https://github.com/rmcolq/pantheon
    runDir = file("${params.fastq}", type: "dir", checkIfExists:true)
    inBarcode_ch = Channel.fromPath("${runDir}/*", type: "dir", checkIfExists:true, maxDepth:1).map { [it.baseName, get_fq_files_in_dir(it)]}
    inMaxLen_ch = Channel.value("${params.max_len}")
    inMinLen_ch = Channel.value("${params.min_len}")
    // pipeline functions below here
    filtered_ch = readFilter(inBarcode_ch, inMaxLen_ch, inMinLen_ch)
}

workflow {
    consensus_wf()
}