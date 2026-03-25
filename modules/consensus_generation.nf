// Processes for read QC and consensus generation will be contained here.

// reads should be adaptor and barcode trimmed by the time they see this pipeline, will add those bits in if needed.
// I'm splitting read length filtering and then primer trimming in case other processes need to be added in between.

process readFilter {
    conda "${HOME}/miniconda3/envs/WaSPPipe_mk2"
    publishDir "${params.out_dir}/${sample_ID}/filtered_reads_1"

    input:
    tuple val(sample_ID), path(sample_ID_files)
    val max_length
    val min_length

    output:
    tuple val(sample_ID), path("*filtered.fastq.gz"), emit: len_filt_reads, optional: true
    path "*"

    script:
    // Vaguely concerned that this is a hacky way to get chopper to take in multiple files, need to think on this.
    """
    conda info
    zcat ${sample_ID_files} | chopper --minlength ${min_length} --maxlength ${max_length} | pigz > ${sample_ID}_filtered.fastq.gz
    """
}

process primerTrimming {
    // At this stage the plan is to just hard trim from the ends of each read.
    conda "${HOME}/miniconda3/envs/WaSPPipe_mk2"
    publishDir "${params.out_dir}/${sample_ID}/primer_trimming_2"

    input:
    tuple val(sample_ID), path(filtered_reads)
    val trim_length

    output:
    tuple val(sample_ID), path("*trimmed.fastq.gz"), emit: trimmed_reads
    path "*"

    script:
    """
    zcat ${filtered_reads} | chopper --trim-approach fixed-crop --headcrop ${trim_length} --tailcrop ${trim_length} | pigz > ${sample_ID}_trimmed.fastq.gz
    """
}

process readMapper {
    // Classic minimap2 of reads to start with, more elaborate approaches may be needed down the line.
    conda "${HOME}/miniconda3/envs/WaSPPipe_mk2"
    publishDir "${params.out_dir}/${sample_ID}/read_mapping_3"

    debug true

    input:
    tuple val(sample_ID), path(trimmed_reads)
    path input_references

    output:
    tuple val(sample_ID), path("*.sorted.bam"), emit: mapped_reads
    path "*.bai", emit: bam_index, optional: true
    path "*.fai", emit: ref_index
    path "*"

    script:
    // The samtools view section removes any unmapped reads from the output bam file for space efficiency.
    // The reference indexing may not be necessary unless there is a new reference specified, could just host the index file like the reference file itself.
    """
    minimap2 -a --secondary=no -x map-ont ${input_references} ${trimmed_reads} | samtools view -b -F 4 - | samtools sort -o ${sample_ID}.sorted.bam -
    samtools index ${sample_ID}.sorted.bam
    samtools faidx ${input_references}
    """
}

// Is it better to separate out each of the references that have reads mapped against them before we move on to the variant calling steps? Possibly...
// Clair3 is happy to call variants on the bam file resulting from mapping against all the viral sequences. 
// Is that more computationally efficient than run samples x N consensus instances or variant calling?
// This may include calling variants on samples below whatever our read depth threshold will be.
// Need to consider if two references are quite close together we might need to re map after an initial mapping to see if we mop anything else up.

process variantCalling {
    // Going to try Clair3 for this...
    // This is the latest docker container for Clair3 as of 20260304
    // NB turns out v2.0.0 is actually bugged in some capacity where it won't find the fasta.fai no matter what I do. Using previous v1.2.0.
    container "hkubal/clair3:v1.2.0"
    publishDir "${params.out_dir}/${sample_ID}/variant_calling_4"

    debug false

    // Need to provide the bam index and reference index; may want to add another step here to deal with that.
    input:
    tuple val(sample_ID), path(mapped_reads)
    path input_references
    path bam_index
    path ref_index

    output:
    tuple val(sample_ID), path("merge_output.vcf.gz"), emit: variant_file, optional: true
    path "merge_output.vcf.gz.tbi", emit: variant_index, optional: true
    path "*", optional: true

    script:
    MODEL_NAME = "r1041_e82_400bps_hac_v410"
    """
    /opt/bin/run_clair3.sh --ref_fn="${input_references}" --bam_fn="${mapped_reads}" --threads=8 --platform="ont" --model_path="/opt/models/${MODEL_NAME}" --output="." --enable_long_indel --chunk_size=10000 --haploid_sensitive --no_phasing_for_fa --include_all_ctgs --enable_variant_calling_at_sequence_head_and_tail
    """
}

process maskGen {
    // Run maskara to get depth masks for the mapped reads.
    conda "${HOME}/miniconda3/envs/WaSPPipe_mk2"
    publishDir "${params.out_dir}/${sample_ID}/mask_generation_5"

    input:
    tuple val(sample_ID), path(mapped_reads)
    path bam_index

    output:
    path "combined_mask.tsv", emit: mask_file

    script:
    """
    maskara -d ${params.depth} -q ${params.baseQ} --reads ${params.read_count} --mmm ${mapped_reads}
    cat *_mask.tsv > combined_mask.tsv
    """
}


process makeConsensus {
    // Apply the mask and variants to their appropriate consensus files.
    // Currently we have one variant file, but X number of mask files. Maybe should create a single large mask file. 
    conda "${HOME}/miniconda3/envs/WaSPPipe_mk2"
    publishDir "${params.out_dir}/${sample_ID}/consensus_generation_6"

    input:
    tuple val(sample_ID), path(variant_file)
    path variant_index
    path mask_file
    path input_references

    output:
    path "masked_consensus_sequences.fasta"

    script:
    // May need to add some variant parsing here or in a separate step.
    """
    bcftools consensus -f ${input_references} -m ${mask_file} -o output.fasta merge_output.vcf.gz ${variant_file}
    python3 ${projectDir}/resources/scripts/fasta_xtractor.py output.fasta ${mask_file} masked_consensus_sequences.fasta
    """
}