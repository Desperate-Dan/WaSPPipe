// Processes for read QC and consensus generation will be contained here.

// reads should be adaptor and barcode trimmed by the time they see this pipeline, will add those bits in if needed.
// I'm splitting read length filtering and then primer trimming in case other processes need to be added in between

process readFilter {
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "results/${sample_ID}/trimmed_reads_1", pattern: "*filtered.fastq.gz"

    input:
    tuple val(sample_ID), path(sample_ID_files)
    val max_length
    val min_length

    output:
    tuple val(sample_ID), path("*filtered.fastq.gz")

    script:
    """
    chopper --minlength ${min_length} --maxlength ${max_length} --input ${sample_ID_files} > ${sample_ID}_filtered.fastq.gz
    """
}