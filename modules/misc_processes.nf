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