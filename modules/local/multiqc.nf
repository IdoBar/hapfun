// Save as: modules/local/multiqc.nf

process MULTIQC {
    label 'process_low'
    conda "bioconda::multiqc=1.19"
    container 'quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0'

    input: 
    path multiqc_files
    path multiqc_config // NEW: Accept the config file

    output:
        path "multiqc_report.html", emit: report
        path "multiqc_data", emit: data

    script:
    """
    multiqc -c $multiqc_config .
    """
}