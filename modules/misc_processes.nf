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