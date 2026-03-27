// Save as: modules/local/aligners.nf

process BWA_ALIGN {
    tag "$meta.id"
    label 'process_high'
    conda "bioconda::bwa-mem2=2.3"
    container 'quay.io/biocontainers/bwa-mem2:2.3--he70b90d_0'
    
    input:
        tuple val(meta), path(read1), path(read2)
        path index_dir
        val prefix
        
    output: tuple val(meta), path("*.sam"), emit: sam
    
    script:
    def args = task.ext.args ?: ''
    """
    bwa-mem2 mem -t ${task.cpus} $args ${index_dir}/${prefix} $read1 $read2 > ${meta.id}_${meta.library}.sam
    """
}

process BOWTIE2_ALIGN {
    tag "$meta.id"
    label 'process_high'
    conda "bioconda::bowtie2=2.5.5"
    container 'quay.io/biocontainers/bowtie2:2.5.5--ha27dd3b_0'

    input:
        tuple val(meta), path(read1), path(read2)
        path index_dir
        val prefix

    output: tuple val(meta), path("*.sam"), emit: sam

    script:
    def args = task.ext.args ?: ''
    """
    bowtie2 -x ${index_dir}/${prefix} -1 $read1 -2 $read2 -p ${task.cpus} $args > ${meta.id}_${meta.library}.sam
    """
}

process SAMTOOLS_SORT_ALIGN {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::samtools=1.23.1"
    container 'quay.io/biocontainers/samtools:1.23.1--ha83d96e_0'

    input:
        tuple val(meta), path(sam)

    output:
        tuple val(meta), path("*.sorted.bam"), emit: bam

    script:
    """
    samtools sort -@ ${task.cpus} -o ${meta.id}_${meta.library}.sorted.bam $sam
    """
}