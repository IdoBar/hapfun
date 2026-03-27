process SAMTOOLS_MERGE {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::samtools=1.23.1"
    container 'quay.io/biocontainers/samtools:1.23.1--ha83d96e_0'
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
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'
    input: tuple val(meta), path(bam)
    output:
        tuple val(meta), path("${meta.id}.dedup.bam"), path("${meta.id}.dedup.bai"), emit: dedup_bam
        path "${meta.id}.metrics.txt", emit: metrics 
    script:
    """
    gatk MarkDuplicates -I $bam -O ${meta.id}.dedup.bam -M ${meta.id}.metrics.txt --CREATE_INDEX true
    """
}

process QUALIMAP {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::qualimap=2.3"
    container 'quay.io/biocontainers/qualimap:2.3--hdfd78af_0'

    input:
    tuple val(meta), path(bam), path(bai)
    path bed // Optional annotation file

    output:
    // Standardized nf-core tuple output, emitting the whole directory
    tuple val(meta), path("${meta.id}_qualimap"), emit: results 

    script:
    // Only append the flag if a bed file was actually staged
    def feature_arg = bed.name != 'NO_FILE' ? "-gff $bed" : ""
    
    """
    unset DISPLAY
    qualimap bamqc \\
        -bam $bam \\
        $feature_arg \\
        -outdir ${meta.id}_qualimap \\
        --java-mem-size=4G
    """
}