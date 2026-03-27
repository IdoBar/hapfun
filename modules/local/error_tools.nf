// Save as: modules/local/error_tools.nf

process MARK_DUPLICATES_LIB {
    tag "${meta.id}_${meta.library}"
    label 'process_medium'
    conda "bioconda::gatk4=4.2.6.1"
    container 'broadinstitute/gatk:4.2.6.1'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.dedup.bam"), path("*.dedup.bai"), emit: dedup_bam
    path "*.metrics.txt", emit: metrics

    script:
    """
    gatk MarkDuplicates \\
        -I $bam \\
        -O ${meta.id}_${meta.library}.dedup.bam \\
        -M ${meta.id}_${meta.library}.metrics.txt \\
        --CREATE_INDEX true
    """
}

process GATK_CALL_LIB {
    tag "${meta.id}_${meta.library}"
    label 'process_medium'
    conda "bioconda::gatk4=4.2.6.1"
    container 'broadinstitute/gatk:4.2.6.1'

    input:
    tuple val(meta), path(bam), path(bai)
    path ref
    path ref_idx 
    path ref_dict 

    output:
    tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: vcf

    script:
    """
    gatk --java-options "-Xmx${task.memory.toGiga()}g" HaplotypeCaller \\
        -R $ref \\
        -I $bam \\
        -O ${meta.id}_${meta.library}.vcf.gz \\
        -ploidy ${params.ploidy}
    """
}

process FREEBAYES_CALL_LIB {
    tag "${meta.id}_${meta.library}"
    label 'process_medium'
    conda "bioconda::freebayes=1.3.5 bioconda::bcftools=1.15"
    container 'quay.io/biocontainers/freebayes:1.3.5--py36hc088bd4_0'

    input:
    tuple val(meta), path(bam), path(bai)
    path ref
    path ref_idx

    output:
    tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.csi"), emit: vcf

    script:
    """
    freebayes -f $ref -p ${params.ploidy} $bam | bgzip > ${meta.id}_${meta.library}.vcf.gz
    bcftools index ${meta.id}_${meta.library}.vcf.gz
    """
}

process VCF_MULTI_COMPARE {
    tag "$meta.id"
    label 'process_low'
    conda "conda-forge::python=3.9 conda-forge::pandas=1.4.2 bioconda::pysam=0.19.1"
    container 'quay.io/biocontainers/mulled-v2-57736af1eb98c01010848572c9fec9e2100823a9:0d650df444747d6928e4695027581b0a56f6259d-0'

    input:
    tuple val(meta), path(vcfs), path(indexes)

    output:
    path "${meta.id}_discordance.csv", emit: report

    script:
    """
    vcf_multi_compare.py \\
        --vcfs $vcfs \\
        --sample ${meta.id} \\
        --out ${meta.id}_discordance.csv
    """
}