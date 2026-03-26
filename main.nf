#!/usr/bin/env nextflow

// Get the modules we need
include { readFilter; primerTrimming; readMapper; variantCalling; maskGen; makeConsensus } from './modules/consensus_generation.nf'

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
    inTrimLen_ch = Channel.value("${params.trim_len}")
    inRefs_ch = Channel.value("${params.ref}")
    // pipeline functions below here
    readFilter(inBarcode_ch, inMaxLen_ch, inMinLen_ch)
    primerTrimming(readFilter.out.len_filt_reads, inTrimLen_ch)
    readMapper(primerTrimming.out.trimmed_reads, inRefs_ch)
    maskGen(readMapper.out.mapped_reads, readMapper.out.bam_index)

    hits_ch = maskGen.out.hits.collect(flat: false) {item -> [item[0], item[1].collect {it -> it.toString().split("/")[-1]}]}
    misses_ch = maskGen.out.misses.collect(flat: false) {item -> [item[0], item[1].toString().split("/")[-1]]}
    hitsAndMisses_ch = hits_ch.flatMap().concat(misses_ch.flatMap())
    hitsAndMisses_ch.collectFile(name: "Ref_matches_report.csv", newLine: true, storeDir: "${launchDir}/output", sort: true) {it -> it.toString().replace("_mask.tsv","").replace("[","").replace("]","").replace(" ","")}

    variantCalling(readMapper.out.mapped_reads, inRefs_ch, readMapper.out.bam_index, readMapper.out.ref_index, maskGen.out.mask_file)
    makeConsensus(variantCalling.out.variant_file, variantCalling.out.variant_index, maskGen.out.mask_file, inRefs_ch)
}

workflow {
    consensus_wf()
}