#!/usr/bin/env nextflow

// Get the modules we need
include { readFilter; primerTrimming; readMapper; topMapper; refFinder; repeatMapper; variantCalling; maskGen; makeConsensus; consensusCat } from './modules/consensus_generation.nf'
include { aphorismGenerator; analysisMetadata; sampleMetadata; metadataCombine } from './modules/misc_processes.nf'
include { kraken2Viral; kraken2Standard8Gb; kronaRun; kronaMulti } from './modules/kraken_analysis.nf'

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
    if (params.database == "Viral") {
        kraken2Viral(inBarcode_ch)
        report_ch = kraken2Viral.out.report
        reports_ch = kraken2Viral.out.reports
    } else if (params.database == "Standard-8Gb") {
        kraken2Standard8Gb(inBarcode_ch)
        report_ch = kraken2Standard8Gb.out.report
        reports_ch = kraken2Standard8Gb.out.reports
    } else {
        error "Unsupported database: ${params.database}"
    }

    if (params.individual_krona) {
        kronaRun(report_ch)
    }
    kronaMulti(reports_ch.collect().sort { it.name })
}

workflow consensus_wf {
    // Define the input channels
    take: 
    inBarcode_ch
    
    main:
    inMaxLen_ch = Channel.value("${params.max_len}")
    inMinLen_ch = Channel.value("${params.min_len}")
    inReadQ_ch = Channel.value("${params.readQ}")
    inTrimLen_ch = Channel.value("${params.trim_len}")
    inRefs_ch = Channel.value("${params.ref}")
    // pipeline functions below here
    readFilter(inBarcode_ch, inMaxLen_ch, inMinLen_ch, inReadQ_ch)
    primerTrimming(readFilter.out.len_filt_reads, inTrimLen_ch)
    readMapper(primerTrimming.out.trimmed_reads, inRefs_ch)
    readCounts_ch = readMapper.out.read_counts.join(readFilter.out.filtered_read_counts).join(readFilter.out.unfiltered_read_counts)
    // Variant pipeline remains consistent between each of the mapping modes, but the input channels will change depending on the mode selected.
    def run_variant_pipeline = { mapped_reads_ch, ref_fasta_ch, bam_index_ch, ref_index_ch, sample_id_ch ->
        maskGen(mapped_reads_ch, bam_index_ch, sample_id_ch)
        combined_ch = mapped_reads_ch.join(ref_fasta_ch).join(bam_index_ch).join(ref_index_ch).join(maskGen.out.mask_file).join(sample_id_ch)
        variantCalling(
            combined_ch.map { [it[0], it[1]] },
            combined_ch.map { [it[0], it[2]] },
            combined_ch.map { [it[0], it[3]] },
            combined_ch.map { [it[0], it[4]] },
            combined_ch.map { [it[0], it[5]] },
            combined_ch.map { [it[0], it[6]] },
            Channel.value("${params.clair3_model}")
        )
        makeConsensus_ch = variantCalling.out.variant_file.join(maskGen.out.mask_file).join(ref_fasta_ch).join(sample_id_ch)
        makeConsensus(
            makeConsensus_ch.map { [it[0], it[1]] },
            makeConsensus_ch.map { [it[0], it[2]] },
            makeConsensus_ch.map { [it[0], it[3]] },
            makeConsensus_ch.map { [it[0], it[4]] }
        )
        return makeConsensus.out.consensus_fasta
    }

    if (params.top_hit_only) {
        topMap_ch = primerTrimming.out.trimmed_reads.join(readMapper.out.read_counts).join(readMapper.out.ref_fasta)
        topMapper(topMap_ch.map { [it[0], it[1]] }, topMap_ch.map { [it[0], it[2]] }, topMap_ch.map { [it[0], it[3]] })
        consensus_ch = run_variant_pipeline(
            topMapper.out.top_mapped_reads,
            topMapper.out.top_ref_fasta,
            topMapper.out.top_bam_index,
            topMapper.out.top_ref_index,
            topMapper.out.original_sample_ID
        )
        coverage_ch = maskGen.out.coverage_data
        readCounts_ch = readCounts_ch.join(topMapper.out.top_read_counts).map { joined_counts ->
            tuple(joined_counts[0], joined_counts[1..-1].flatten())
        }

    } else if (params.remap_all) {
        refFinder_ch = readMapper.out.read_counts.join(readMapper.out.ref_fasta)
        refFinder(refFinder_ch.map { [it[0], it[1]] }, refFinder_ch.map { [it[0], it[2]] })
        newRefs_ch = refFinder.out.repeat_ref_fasta.flatMap { sample, refs -> refs.collect { ref -> tuple(sample, ref) } }
        repeatMap_ch = newRefs_ch.combine(primerTrimming.out.trimmed_reads.map { sample, reads -> tuple(sample, reads) }, by: 0)
        repeatMapper(repeatMap_ch.map { [it[0], it[1]] }, repeatMap_ch.map { [it[0], it[2]] })
        consensus_ch = run_variant_pipeline(
            repeatMapper.out.repeat_mapped_reads,
            repeatMapper.out.repeat_ref_fasta,
            repeatMapper.out.repeat_bam_index,
            repeatMapper.out.repeat_ref_index,
            repeatMapper.out.original_sample_ID
        )
        repeatCounts_ch = repeatMapper.out.repeat_read_counts.groupTuple(by: 0).map { sample_ID, counts_files -> tuple(sample_ID, counts_files.collect { it.toString() }) }
        readCounts_ch = readCounts_ch.join(repeatCounts_ch).map { joined_counts ->
            tuple(joined_counts[0], joined_counts[1..-1].flatten())
        }
        coverage_ch = maskGen.out.coverage_data.groupTuple(by: 0).map { sample, coverage -> tuple(sample, coverage.collect{ it.toString() }) }

        consensus_ch = consensus_ch.groupTuple(by: 0).map { sample_ID, fasta_files -> tuple(sample_ID, fasta_files.collect { it.toString() }) }
        consensusCat(consensus_ch.map { [it[0], it[1]] })
    } else {
        consensus_ch = run_variant_pipeline(
            readMapper.out.mapped_reads,
            readMapper.out.ref_fasta,
            readMapper.out.bam_index,
            readMapper.out.ref_index,
            readMapper.out.original_sample_ID
        )
        coverage_ch = maskGen.out.coverage_data
        consensusCat(consensus_ch.map { [it[0], it[1]] })
        readCounts_ch = readCounts_ch.map { read_counts ->
            tuple(read_counts[0], read_counts[1..-1].flatten())
        }
    }
    
    hits_ch = maskGen.out.hits.collect(flat: false) {item -> [item[0], item[1] instanceof ArrayList ? item[1].collect {it -> it.toString().split("/")[-1]} : item[1].toString().split("/")[-1]]}
    misses_ch = maskGen.out.misses.collect(flat: false) {item -> [item[0], item[1].toString().split("/")[-1]]}
    hitsAndMisses_ch = hits_ch.flatMap().concat(misses_ch.flatMap())
    hitsAndMisses_ch.collectFile(name: "Ref_matches_report.csv", newLine: true, storeDir: "${launchDir}/output", sort: true) {it -> it.toString().replace("_mask.tsv","").replace("[","").replace("]","").replace(" ","")}
    analysisMetadata(hitsAndMisses_ch.collect(), Channel.value("${params.run_ID}"))
    
    metadata_ch = readCounts_ch.join(consensus_ch).join(coverage_ch)
    sampleMetadata(metadata_ch.map { [it[0], it[1]] }, inRefs_ch, metadata_ch.map { [it[0], it[2]] }, metadata_ch.map { [it[0], it[3]] })
    metadataCombine(sampleMetadata.out.sample_metadata.collect(), Channel.value("${params.run_ID}"))
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