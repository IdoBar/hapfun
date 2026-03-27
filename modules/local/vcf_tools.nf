process BCFTOOLS_MERGE {
    label 'process_medium'
    conda "bioconda::bcftools=1.23.1"
    container 'quay.io/biocontainers/bcftools:1.23.1--hb2cee57_0'
    input:
        path vcfs
        path tbis
    output: path "merged.vcf.gz", emit: vcf
    script:
    """
    bcftools merge --force-samples -O z -o merged.vcf.gz $vcfs
    """
}

process BCFTOOLS_STATS {
    tag "$meta.id"
    label 'process_low'
    conda "bioconda::bcftools=1.23.1"
    container 'quay.io/biocontainers/bcftools:1.23.1--hb2cee57_0'
    input: tuple val(meta), path(vcf)
    output: path "${meta.id}.vcf.stats", emit: stats 
    script:
    """
    bcftools stats $vcf > ${meta.id}.vcf.stats
    """
}
