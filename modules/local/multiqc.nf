process MULTIQC {
    label 'process_low'
    conda "bioconda::multiqc=1.19"
    container 'quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0'
    input: 
    file multiqc_files
    file multiqc_config from ch_config_for_multiqc
    output:
        file "multiqc_report.html"
        file "multiqc_data"
    script:
    rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
    rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''
    """
    multiqc --config $multiqc_config $rtitle $rfilename .
    """
}


/* params.multiqc_config = "$baseDir/assets/multiqc_config.yaml"
Channel.fromPath(params.multiqc_config, checkIfExists: true).set { ch_config_for_multiqc }

process multiqc {
    input:
    file multiqc_config from ch_config_for_multiqc
    file ('fastqc/*') from fastqc_results.collect().ifEmpty([])

    output:
    file "multiqc_report.html" into multiqc_report
    file "multiqc_data"

    script:
    rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
    rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''
    """
    multiqc --config $multiqc_config $rtitle $rfilename .
    """
} */