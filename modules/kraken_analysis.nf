// Add some commands to run kraken2 analysis of the reads
// Will probably be optional
// Probably should make a custom database of the family reference viruses... Maybe add that to the preexisting viral database for extra coverage?
// Are human reads a consideration? - not really, the 8Gb standard doesn't pick up much

process kraken2Run {
    container "${params.viral_db}@${params.viral_db_sha}"
    publishDir "output/${sample_ID}/kraken2_krona_plots", mode: 'copy'

    debug false

    input:
    // Plan to run on raw input reads, but may need to consider trimming beforehand.
    tuple val(sample_ID), path(sample_ID_files)

    output:
    tuple val(sample_ID), path("*_report.txt"), emit: report
    path("*_report.txt"), emit: reports
    path "*"

    script:
    """
    kraken2 --db /tmp/viral_standard_20260330/ --output ${sample_ID}_vsd_ouput.txt --report ${sample_ID}_vsd_report.txt ${sample_ID_files}
    """
}

process kronaRun {
    container "${params.viral_db}@${params.viral_db_sha}"
    publishDir "output/${sample_ID}/kraken2_krona_plots", mode: 'copy'

    debug false

    input:
    tuple val(sample_ID), path(report)

    output:
    path "*"

    script:
    """
    ktImportTaxonomy -t 5 -m 3 -o ${sample_ID}_krona.html ${report}
    """
}

process kronaMulti {
    container "${params.viral_db}@${params.viral_db_sha}"
    publishDir "output/kraken2_krona_plots_combined", mode: 'copy'

    debug false

    input:
    path(reports)

    output:
    path "*"

    script:
    """
    ktImportTaxonomy -t 5 -m 3 -o Multi_krona.html ${reports}
    """
}
