// Save as: modules/local/error_tools.nf

process MARK_DUPLICATES_LIB {
    tag "${meta.id}_${meta.library}"
    label 'process_medium'
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'

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
        --CREATE_INDEX true \\
        --READ_NAME_REGEX null
    """
}

process GATK_CALL_LIB {
    tag "${meta.id}_${meta.library}"
    label 'process_medium'
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'

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
    conda "bioconda::freebayes=1.3.10"
    container 'quay.io/biocontainers/freebayes:1.3.10--hbefcdb2_0'

    input:
    tuple val(meta), path(bam), path(bai)
    path ref
    path ref_idx

    output:
    tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: vcf

    script:
    """
    freebayes -f $ref -p ${params.ploidy} $bam | bgzip > ${meta.id}_${meta.library}.vcf.gz
    tabix ${meta.id}_${meta.library}.vcf.gz
    """
}

process VCF_MULTI_COMPARE {
    tag "$meta.id"
    label 'process_low'
    conda "conda-forge::python=3.9 conda-forge::pandas=1.4.2 bioconda::pysam=0.19.1"
    container 'quay.io/biocontainers/mulled-v2-629aec3ba267b06a1efc3ec454c0f09e134f6ee2:3b083bb5eae6e491b8579589b070fa29afbea2a1-0'

    input:
    tuple val(meta), path(vcfs), path(indexes)
    path compare_script

    output:
    path "${meta.id}_discordance.csv", emit: report

    script:
    """
    python $compare_script \\
        --vcfs $vcfs \\
        --sample ${meta.id} \\
        --out ${meta.id}_discordance.csv
    """
}