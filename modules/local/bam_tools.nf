process SAMTOOLS_MERGE {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::samtools=1.15"
    container 'quay.io/biocontainers/samtools:1.15--h3843585_0'
    input: tuple val(meta), path(bams)
    output: tuple val(meta), path("${meta.id}.merged.bam"), emit: merged_bam
    script:
    """
    samtools merge -@ ${task.cpus} ${meta.id}.merged.bam $bams
    """
}

process MARK_DUPLICATES {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::gatk4=4.2.6.1"
    container 'broadinstitute/gatk:4.2.6.1'
    input: tuple val(meta), path(bam)
    output:
        tuple val(meta), path("${meta.id}.dedup.bam"), path("${meta.id}.dedup.bai"), emit: dedup_bam
        path "${meta.id}.metrics.txt", emit: metrics 
    script:
    """
    gatk MarkDuplicates -I $bam -O ${meta.id}.dedup.bam -M ${meta.id}.metrics.txt --CREATE_INDEX true
    """
}
