// Save as: modules/local/aligners.nf

process BWA_ALIGN {
    tag "$meta.id"
    label 'process_high'
    conda "bioconda::bwa-mem2=2.3 bioconda::samtools=1.23.1"
    container 'quay.io/biocontainers/bwa-mem2:2.3--he70b90d_0'
    
    input:
        tuple val(meta), path(reads)
        path index_dir
        val prefix
        
    output: tuple val(meta), path("*.sorted.bam"), emit: bam
    
    script:
    def args = task.ext.args ?: ''
    """
    bwa-mem2 mem -t ${task.cpus} $args ${index_dir}/${prefix} ${reads[0]} ${reads[1]} | \\
    samtools sort -@ ${task.cpus} -o ${meta.id}_${meta.library}.sorted.bam -
    """
}

process BOWTIE2_ALIGN {
    tag "$meta.id"
    label 'process_high'
    conda "bioconda::bowtie2=2.5.5 bioconda::samtools=1.23.1"
    container 'quay.io/biocontainers/bowtie2:2.5.5--ha27dd3b_0'

    input:
        tuple val(meta), path(reads)
        path index_dir
        val prefix

    output: tuple val(meta), path("*.sorted.bam"), emit: bam

    script:
    def args = task.ext.args ?: ''
    """
    bowtie2 -x ${index_dir}/${prefix} -1 ${reads[0]} -2 ${reads[1]} -p ${task.cpus} $args | \\
    samtools sort -@ ${task.cpus} -o ${meta.id}_${meta.library}.sorted.bam -
    """
}