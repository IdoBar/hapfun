process FASTP {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::fastp=0.23.4"
    container 'quay.io/biocontainers/fastp:0.23.4--hadf994f_2'
    
    input: tuple val(meta), path(reads)
    output:
        tuple val(meta), path("*_1.fastp.fq.gz"), path("*_2.fastp.fq.gz"), emit: trimmed_reads
        path "*.json", emit: json 
        path "*.html", emit: html
    script:
    def args = task.ext.args ?: ''
    """
    fastp --in1 ${reads[0]} --in2 ${reads[1]} --out1 ${meta.id}_${meta.library}_1.fastp.fq.gz --out2 ${meta.id}_${meta.library}_2.fastp.fq.gz --json ${meta.id}_${meta.library}.fastp.json --html ${meta.id}_${meta.library}.fastp.html --thread ${task.cpus} $args
    """
}
