// Processes for read QC and consensus generation will be contained here.

// reads should be adaptor and barcode trimmed by the time they see this pipeline, will add those bits in if needed.
// I'm splitting read length filtering and then primer trimming in case other processes need to be added in between.

process readFilter {
    container "${params.consensus_func}@${params.consensus_func_sha}"
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "output/${sample_ID}/filtered_reads_1", mode: "copy"

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
    zcat ${sample_ID_files} | chopper --minlength ${min_length} --maxlength ${max_length} | pigz > ${sample_ID}_filtered.fastq.gz
    """
}

process primerTrimming {
    // At this stage the plan is to just hard trim from the ends of each read.
    container "${params.consensus_func}@${params.consensus_func_sha}"
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "output/${sample_ID}/primer_trimming_2", mode: "copy"

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
    container "${params.consensus_func}@${params.consensus_func_sha}"
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "output/${sample_ID}/read_mapping_3", mode: "copy"

    debug true

    input:
    tuple val(sample_ID), path(trimmed_reads)
    path input_references

    output:
    tuple val(sample_ID), path("*.sorted.bam"), emit: mapped_reads
    tuple val(sample_ID), path("*.bai"), emit: bam_index, optional: true
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

process maskGen {
    // Run maskara to get depth masks for the mapped reads.
    container "${params.consensus_func}@${params.consensus_func_sha}"
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "output/${sample_ID}/mask_generation_4", mode: "copy"

    input:
    tuple val(sample_ID), path(mapped_reads)
    tuple val(sample_ID), path(bam_index)

    output:
    tuple val(sample_ID), path("*_combined_masks.tsv"), emit: mask_file, optional: true

    tuple val(sample_ID), path("*_mask.tsv"), emit: hits, optional: true
    tuple val(sample_ID), path("NO_REF*"), emit: misses, optional: true

    script:
    // The use of compgen bothers me a bit (can't use [] as it doesn't support glob), but as long as it's run on BASH it should be okay.
    """
    maskara -d ${params.depth} -q ${params.baseQ} --reads ${params.read_count} --mmm ${mapped_reads}
    if compgen -G *_mask.tsv; then cat *_mask.tsv > ${sample_ID}_combined_masks.tsv; else touch NO_REF_WITH_MORE_THAN_${params.read_count}_READS; fi
    """
}

process variantCalling {
    // Going to try Clair3 for this...
    // This is the latest docker container for Clair3 as of 20260304
    // NB turns out v2.0.0 is actually bugged in some capacity where it won't find the fasta.fai no matter what I do. Using previous v1.2.0.
    container "hkubal/clair3:v1.2.0"
    publishDir "output/${sample_ID}/variant_calling_5", mode: "copy"

    debug false

    // Need to provide the bam index and reference index; may want to add another step here to deal with that.
    input:
    tuple val(sample_ID), path(mapped_reads)
    path input_references
    tuple val(sample_ID), path(bam_index)
    path ref_index
    tuple val(sample_ID), path (mask_file) // adding the mask file just to ensure we only call variants on samples we can make a ref from. NB This doesn't actually work! it gives a random maskfile... will add channel parsing to main.nf

    output:
    tuple val(sample_ID), path("*_merge_output.vcf.gz"), emit: variant_file, optional: true
    path "*", optional: true

    script:
    MODEL_NAME = "r1041_e82_400bps_hac_v410"
    """
    /opt/bin/run_clair3.sh --ref_fn="${input_references}" --bam_fn="${mapped_reads}" --threads=8 --platform="ont" --model_path="/opt/models/${MODEL_NAME}" --output="." --enable_long_indel --chunk_size=10000 --haploid_sensitive --no_phasing_for_fa --include_all_ctgs --enable_variant_calling_at_sequence_head_and_tail
    if [ -f merge_output.vcf.gz ]; then mv merge_output.vcf.gz ${sample_ID}_merge_output.vcf.gz; fi
    if [ -d tmp ]; then rm -r tmp; fi
    """
}

process makeConsensus {
    // Apply the mask and variants to their appropriate consensus files.
    container "${params.consensus_func}@${params.consensus_func_sha}"
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "output/${sample_ID}/consensus_generation_6", mode: "copy"

    input:
    tuple val(sample_ID), path(variant_file)
    tuple val(sample_ID), path (mask_file)
    path input_references

    output:
    path "${sample_ID}*.fasta"

    script:
    // May need to add some variant parsing here or in a separate step.
    """
    bcftools index -t ${variant_file}
    bcftools consensus -f ${input_references} -m ${mask_file} -o temp.fasta ${variant_file}
    python3 ${projectDir}/resources/scripts/fasta_xtractor.py temp.fasta ${mask_file} ${sample_ID}
    if compgen -G ${sample_ID}*.fasta; then cat ${sample_ID}*.fasta > ${sample_ID}_combined.fasta; fi
    """
}
