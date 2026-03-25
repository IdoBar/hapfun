process FREEBAYES {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::freebayes=1.3.5 bioconda::bcftools=1.15"
    container 'quay.io/biocontainers/freebayes:1.3.5--py36hc088bd4_0'
    input:
        tuple val(meta), path(bam), path(bai)
        path ref
        path ref_idx
    output:
        path "${meta.id}.vcf.gz", emit: vcf
        path "${meta.id}.vcf.gz.csi", emit: csi
    script:
    def args = task.ext.args ?: ''
    """
    freebayes -f $ref $args $bam | bgzip > ${meta.id}.vcf.gz
    bcftools index ${meta.id}.vcf.gz
    """
}

process FREEBAYES_POPULATION {
    label 'process_high'
    conda "bioconda::freebayes=1.3.5 bioconda::bcftools=1.15"
    container 'quay.io/biocontainers/freebayes:1.3.5--py36hc088bd4_0'
    input:
        path bams
        path bais
        path ref
        path ref_idx
    output: path "population.vcf.gz", emit: vcf
    script:
    def args = task.ext.args ?: ''
    """
    freebayes -f $ref $args $bams | bgzip > population.vcf.gz
    """
}
