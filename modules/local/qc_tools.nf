// Save as: modules/local/qc_tools.nf

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

process FASTQC {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::fastqc=0.11.9"
    container 'quay.io/biocontainers/fastqc:0.11.9--0'
    
    input: tuple val(meta), path(reads)
    output: path "*.{html,zip}", emit: results
    
    script:
    """
    fastqc -t ${task.cpus} -q ${reads[0]} ${reads[1]}
    """
}

process TRIMMOMATIC {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::trimmomatic=0.39"
    container 'quay.io/biocontainers/trimmomatic:0.39--1'
    
    input: tuple val(meta), path(reads)
    output:
        tuple val(meta), path("*_1.paired.fq.gz"), path("*_2.paired.fq.gz"), emit: trimmed_reads
        path "*.trim.log", emit: log 
        
    script:
    def args = task.ext.args ?: ''
    """
    trimmomatic PE -threads ${task.cpus} \\
    ${reads[0]} ${reads[1]} \\
    ${meta.id}_${meta.library}_1.paired.fq.gz ${meta.id}_${meta.library}_1.unpaired.fq.gz \\
    ${meta.id}_${meta.library}_2.paired.fq.gz ${meta.id}_${meta.library}_2.unpaired.fq.gz \\
    $args \\
    2> ${meta.id}_${meta.library}.trim.log
    """
}