process BWA_ALIGN {
    tag "$meta.id"
    label 'process_high'
    conda "bioconda::bwa-mem2=2.2.1 bioconda::samtools=1.15"
    container 'quay.io/biocontainers/bwa-mem2:2.2.1--he513fc3_0'
    
    input:
        tuple val(meta), path(reads)
        path ref
    output: tuple val(meta), path("*.sorted.bam"), emit: bam
    script:
    def args = task.ext.args ?: ''
    """
    bwa-mem2 mem -t ${task.cpus} $args $ref ${reads[0]} ${reads[1]} | samtools sort -@ ${task.cpus} -o ${meta.id}_${meta.library}.sorted.bam -
    """
}
