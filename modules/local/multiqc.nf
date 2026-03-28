// Save as: modules/local/multiqc.nf

process MULTIQC {
    label 'process_low'
    conda "bioconda::multiqc=1.33"
    container 'quay.io/biocontainers/multiqc:1.33--pyhdfd78af_0'

    input: 
    path multiqc_files
    path multiqc_config
    path multiqc_logo   // staged alongside config so relative path in YAML resolves

    output:
        path "multiqc_report.html", emit: report
        path "*_data", emit: data

    script:
    """
    multiqc -n multiqc_report.html -c $multiqc_config .
    """
}