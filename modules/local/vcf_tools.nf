process BCFTOOLS_MERGE {
    label 'sc_medium'
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

process BCFTOOLS_CONCAT {
    label 'sc_medium'
    conda "bioconda::bcftools=1.23.1"
    container 'quay.io/biocontainers/bcftools:1.23.1--hb2cee57_0'
    input:
        tuple path(vcfs), path(tbis)
    output:
        path "population.vcf.gz", emit: vcf
        path "population.vcf.gz.tbi", emit: tbi
    script:
    """
    printf '%s\n' $vcfs > vcf_list.txt
    bcftools concat -f vcf_list.txt -Oz -o population.vcf.gz
    tabix -p vcf population.vcf.gz
    """
}

process BCFTOOLS_STATS {
    tag "$meta.id"
    label 'sc_medium'
    conda "bioconda::bcftools=1.23.1"
    container 'quay.io/biocontainers/bcftools:1.23.1--hb2cee57_0'
    input: tuple val(meta), path(vcf)
    output: path "${meta.id}.vcf.stats", emit: stats 
    script:
    """
    bcftools stats $vcf > ${meta.id}.vcf.stats
    """
}
