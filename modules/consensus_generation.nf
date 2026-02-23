// Processes for read QC and consensus generation will be contained here.

// reads should be adaptor and barcode trimmed by the time they see this pipeline, will add those bits in if needed.
// I'm splitting read length filtering and then primer trimming in case other processes need to be added in between

process readFilter {
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "results/${sample_ID}/filtered_reads_1", pattern: "*filtered.fastq.gz"

    input:
    tuple val(sample_ID), path(sample_ID_files)
    val max_length
    val min_length

    output:
    tuple val(sample_ID), path("*filtered.fastq.gz")

    script:
    // Vaguely concerned that this is a hacky way to get chopper to take in multiple files, need to think on this.
    """
    zcat ${sample_ID_files} | chopper --minlength ${min_length} --maxlength ${max_length} > ${sample_ID}_filtered.fastq.gz
    """
}

process primerTrimming {
    // At this stage the plan is to just hard trim from the ends of each read.
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "results/${sample_ID}/primer_trimming_2", pattern: "*trimmed.fastq.gz"

    input:
    tuple val(sample_ID), path(filtered_reads)
    val trim_length

    output:
    tuple val(sample_ID), path("*trimmed.fastq.gz")

    script:
    """
    zcat ${sample_ID_files} | chopper --trim-approach fixed-crop --headcrop trim_length --tailcrop trim_length
}

process readMapper {

}