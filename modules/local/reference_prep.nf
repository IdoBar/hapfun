// Save as: modules/local/reference_prep.nf

process SAMTOOLS_FAIDX {
    tag "$fasta"
    label 'process_low'
    conda "bioconda::samtools=1.15"
    container 'quay.io/biocontainers/samtools:1.15--h3843585_0'

    input:
    path fasta

    output:
    path "*.fai", emit: fai

    script:
    """
    samtools faidx $fasta
    """
}

process GATK_DICTIONARY {
    tag "$fasta"
    label 'process_low'
    conda "bioconda::gatk4=4.2.6.1"
    container 'broadinstitute/gatk:4.2.6.1'

    input:
    path fasta

    output:
    path "*.dict", emit: dict

    script:
    // Regex to strip .fa or .fasta extension and replace with .dict
    def dict_name = fasta.name.replaceAll(/\\.fa(sta)?\$/, ".dict")
    
    """
    gatk CreateSequenceDictionary -R $fasta -O $dict_name
    """
}

process BWA_INDEX {
    tag "$fasta"
    label 'process_high'
    conda "bioconda::bwa-mem2=2.2.1"
    container 'quay.io/biocontainers/bwa-mem2:2.2.1--he513fc3_0'

    input: path fasta
    output: path "bwa_index", emit: index

    script:
    """
    mkdir bwa_index
    # Symlink the fasta into the dir so bwa-mem2 writes indices next to it
    ln -s \$(readlink -f $fasta) bwa_index/${fasta.name}
    bwa-mem2 index bwa_index/${fasta.name}
    """
}

process BOWTIE2_INDEX {
    tag "$fasta"
    label 'process_high'
    conda "bioconda::bowtie2=2.4.4"
    container 'quay.io/biocontainers/bowtie2:2.4.4--py39hbb4e92a_0'

    input: path fasta
    output: path "bowtie2_index", emit: index

    script:
    """
    mkdir bowtie2_index
    bowtie2-build --threads ${task.cpus} $fasta bowtie2_index/${fasta.name}
    """
}