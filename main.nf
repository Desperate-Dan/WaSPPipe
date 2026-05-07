#!/usr/bin/env nextflow

// Get the modules we need
include { readFilter; primerTrimming; readMapper; variantCalling; maskGen; makeConsensus } from './modules/consensus_generation.nf'
include { aphorismGenerator } from './modules/misc_processes.nf'
include { kraken2Run; kronaRun; kronaMulti } from './modules/kraken_analysis.nf'

//These lines for fastq dir parsing are taken from rmcolq's workflow https://github.com/rmcolq/pantheon
EXTENSIONS = ["fastq", "fastq.gz", "fq", "fq.gz"]

ArrayList get_fq_files_in_dir(Path dir) {
    return EXTENSIONS.collect { file(dir.resolve("*.$it"), type: "file") } .flatten()
}

workflow aphorism_wf {
    aphoFile_ch = Channel.fromPath("${params.aphorisms}")
    aphorismGenerator(aphoFile_ch)
}

workflow kraken_wf {
    take:
    inBarcode_ch
    
    main:
    kraken2Run(inBarcode_ch)
    if (params.individual_krona) {
        kronaRun(kraken2Run.out.report)    
    }
    kronaMulti(kraken2Run.out.reports.collect().sort { it.name })
}

workflow consensus_wf {
    // Define the input channels
    take: 
    inBarcode_ch
    
    main:
    inMaxLen_ch = Channel.value("${params.max_len}")
    inMinLen_ch = Channel.value("${params.min_len}")
    inTrimLen_ch = Channel.value("${params.trim_len}")
    inRefs_ch = Channel.value("${params.ref}")
    // pipeline functions below here
    readFilter(inBarcode_ch, inMaxLen_ch, inMinLen_ch)
    primerTrimming(readFilter.out.len_filt_reads, inTrimLen_ch)
    readMapper(primerTrimming.out.trimmed_reads, inRefs_ch)
    maskGen(readMapper.out.mapped_reads, readMapper.out.bam_index)

    hits_ch = maskGen.out.hits.collect(flat: false) {item -> [item[0], item[1] instanceof ArrayList ? item[1].collect {it -> it.toString().split("/")[-1]} : item[1].toString().split("/")[-1]]}
    misses_ch = maskGen.out.misses.collect(flat: false) {item -> [item[0], item[1].toString().split("/")[-1]]}
    hitsAndMisses_ch = hits_ch.flatMap().concat(misses_ch.flatMap())
    hitsAndMisses_ch.collectFile(name: "Ref_matches_report.csv", newLine: true, storeDir: "${launchDir}/output", sort: true) {it -> it.toString().replace("_mask.tsv","").replace("[","").replace("]","").replace(" ","")}

    // Join the outputs of maskGen and readMapper, keyed by barcode number
    combined_ch = readMapper.out.mapped_reads.join(readMapper.out.bam_index).join(maskGen.out.mask_file)
    variantCalling(combined_ch.map { [it[0], it[1]] }, inRefs_ch, combined_ch.map { [it[0], it[2]] }, readMapper.out.ref_index, combined_ch.map { [it[0], it[3]] })
    
    // Join the outputs of variantCalling with mask files, keyed by barcode number
    makeConsensus_ch = variantCalling.out.variant_file.join(maskGen.out.mask_file)
    makeConsensus(makeConsensus_ch.map { [it[0], it[1]] }, makeConsensus_ch.map { [it[0], it[2]] }, inRefs_ch)
}

workflow {
    if (params.aphorisms) {
        aphorism_wf()
    }
    
    // These lines for fastq dir parsing have been modified from rmcolq's workflow https://github.com/rmcolq/pantheon
    runDir = file("${params.fastq}", type: "dir", checkIfExists:true)
    if (!params.parse_all) {
        prefix = "barcode"
    } else {
        prefix = ""
    }
    
    inBarcode_ch = Channel.fromPath("${runDir}/" + prefix + "*", type: "dir", checkIfExists:true, maxDepth:1).map { [it.baseName, get_fq_files_in_dir(it)]}
    
    kraken_wf(inBarcode_ch)
    consensus_wf(inBarcode_ch)
    
}