process FREEBAYES {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::freebayes=1.3.10"
    container 'quay.io/biocontainers/freebayes:1.3.10--hbefcdb2_0'
    input:
        tuple val(meta), path(bam), path(bai)
        path ref
        path ref_idx
    output:
        path "${meta.id}.vcf.gz", emit: vcf
        path "${meta.id}.vcf.gz.tbi", emit: tbi
    script:
    def args = task.ext.args ?: ''
    """
    freebayes -f $ref -p ${params.ploidy} $args $bam | bgzip > ${meta.id}.vcf.gz
    tabix ${meta.id}.vcf.gz
    """
}

process FREEBAYES_POPULATION {
    label 'process_high'
    conda "bioconda::freebayes=1.3.10"
    container 'quay.io/biocontainers/freebayes:1.3.10--hbefcdb2_0'
    input:
        path bams
        path bais
        path ref
        path ref_idx
    output: path "population.vcf.gz", emit: vcf
    script:
    def args = task.ext.args ?: ''
    """
    freebayes -f $ref -p ${params.ploidy} $args $bams | bgzip > population.vcf.gz
    """
}

process GATK_HAPLOTYPECALLER {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'

    input:
    tuple val(meta), path(bam), path(bai)
    path ref
    path ref_idx 
    path ref_dict 

    output:
    tuple val(meta), path("*.g.vcf.gz"), path("*.g.vcf.gz.tbi"), emit: gvcf

    script:
    def args = task.ext.args ?: ''
    """
    gatk --java-options "-Xmx${task.memory.toGiga()}g" HaplotypeCaller \\
        -R $ref \\
        -I $bam \\
        -O ${meta.id}.g.vcf.gz \\
        -ERC GVCF \\
        -ploidy ${params.ploidy} \\
        $args
    """
}

process GATK_COMBINEGVCFS {
    label 'process_medium'
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'

    input:
    path gvcfs
    path tbis
    path ref
    path ref_idx
    path ref_dict

    output:
    path "cohort.g.vcf.gz", emit: gvcf
    path "cohort.g.vcf.gz.tbi", emit: tbi

    script:
    // Dynamically build the -V arguments for all input gVCFs
    def input_args = gvcfs.collect { "-V $it" }.join(' ')
    """
    gatk --java-options "-Xmx${task.memory.toGiga()}g" CombineGVCFs \\
        -R $ref \\
        $input_args \\
        -O cohort.g.vcf.gz
    """
}

process GATK_GENOTYPEGVCFS {
    label 'process_medium'
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'

    input:
    path gvcf
    path tbi
    path ref
    path ref_idx
    path ref_dict

    output:
    path "joint_called.vcf.gz", emit: vcf
    path "joint_called.vcf.gz.tbi", emit: tbi

    script:
    """
    gatk --java-options "-Xmx${task.memory.toGiga()}g" GenotypeGVCFs \\
        -R $ref \\
        -V $gvcf \\
        -O joint_called.vcf.gz
    """
}