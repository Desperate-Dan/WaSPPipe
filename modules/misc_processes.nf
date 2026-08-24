// Some process not easily categorised into the other modules

process aphorismGenerator {
    // Adding the below to ensure this nonsense doen't stop the pipeline in its tracks
    errorStrategy 'ignore'
    
    debug true

    input:
    path aphorism_file

    output:
    stdout

    script:
    """
    random_line.py ${aphorism_file}
    """
    

}

process analysisMetadata {
    publishDir "output", mode: "copy"

    input:
    val hitsAndMisses
    val run_ID

    output:
    file "Analysis_metadata.csv"

    script:
    def TIME = new Date().format("yyyy-MM-dd HH:mm:ss")
    """
    touch Analysis_metadata.csv
    echo "run_ID,${run_ID}" > Analysis_metadata.csv
    echo "WaSPPipe_version,${params.version}" >> Analysis_metadata.csv
    echo "Timestamp,${TIME}" >> Analysis_metadata.csv
    """
}

process sampleMetadata {
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "output/${sample_ID}/", mode: "copy"

    debug true

    input:
    tuple val(sample_ID), val(read_count_files)
    path input_references
    tuple val(sample_ID), val(consensus_seqs)

    output:
    path ("*_sample_metadata.csv"), emit: sample_metadata
    stdout

    script:
    """
    metadata_assembler.py --reference_file ${input_references} --consensus_files "${consensus_seqs}" -r "${read_count_files}"
    """
}

process metadataCombine {
    conda "${HOME}/miniconda3/envs/WaSPPipe"
    publishDir "output/", mode: "copy"

    debug true

    input:
    path sample_metadata_files
    val run_ID

    output:
    path ("*run_metadata.csv")

    script:
    """
    metadata_combiner.py --metadata_files "${sample_metadata_files}" --run_id ${run_ID}
    """

}