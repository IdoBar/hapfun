process FREEBAYES {
    tag "$meta.id"
    label 'mc_medium'
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
    def maxInnerThreads = (params.caller_inner_threads ?: 4) as Integer
    def threads = Math.max(1, Math.min((task.cpus ?: 1) as Integer, maxInnerThreads))
    """
    awk '{ print \$1 ":1-" \$2 }' $ref_idx > chromosome_regions.txt

    freebayes-parallel chromosome_regions.txt ${threads} -f $ref -p ${params.ploidy} $args $bam | bgzip -c > ${meta.id}.vcf.gz
    tabix -p vcf ${meta.id}.vcf.gz
    """
}

process FREEBAYES_POPULATION {
    tag "$meta.id"
    label 'mc_large'
    conda "bioconda::freebayes=1.3.10"
    container 'quay.io/biocontainers/freebayes:1.3.10--hbefcdb2_0'
    input:
        tuple val(meta), path(region_file), path(bams), path(bais), path(ref), path(ref_idx)
    output:
        tuple val(meta), path("${meta.id}.vcf.gz"), path("${meta.id}.vcf.gz.tbi"), emit: vcf
    script:
    def args = task.ext.args ?: ''
    def maxInnerThreads = (params.caller_inner_threads ?: 4) as Integer
    def threads = Math.max(1, Math.min((task.cpus ?: 1) as Integer, maxInnerThreads))
    """
    find -L . -type f -name '*.bam' | sort > bam_list.txt
    [ -s bam_list.txt ] || { echo 'No staged BAM inputs discovered for FREEBAYES_POPULATION' >&2; exit 1; }

    freebayes-parallel $region_file ${threads} -f $ref -p ${params.ploidy} $args -L bam_list.txt | bgzip -c > ${meta.id}.vcf.gz
    tabix -p vcf ${meta.id}.vcf.gz
    """
}

process GATK_HAPLOTYPECALLER {
    tag "$meta.id"
    label 'mc_medium'
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'

    input:
    tuple val(meta), path(bam), path(bai)
    path ref
    path ref_idx 
    path ref_dict 

    output:
    tuple val(meta), path("*.g.vcf.gz"), path("*.g.vcf.gz.tbi"), emit: gvcf

    shell:
    def args = task.ext.args ?: ''
    def maxInnerThreads = (params.caller_inner_threads ?: 4) as Integer
    def threads = Math.max(1, Math.min((task.cpus ?: 1) as Integer, maxInnerThreads))
    '''
    awk '{ print $1 }' !{ref_idx} > chromosomes.txt

    max_jobs=!{threads}
    while IFS= read -r chrom; do
        (
            gatk --java-options "-Xmx!{task.memory.toGiga()}g" HaplotypeCaller \
                -R !{ref} \
                -I !{bam} \
                -L "$chrom" \
                -O "${chrom}.g.vcf.gz" \
                -ERC GVCF \
                -ploidy !{params.ploidy} \
                --native-pair-hmm-threads 1 \
                !{args}
            tabix -p vcf "${chrom}.g.vcf.gz"
        ) &

        while [ "$(jobs -pr | wc -l)" -ge "$max_jobs" ]; do
            wait -n
        done
    done < chromosomes.txt

    wait

    gather_args=$(awk '{ printf " -I %s.g.vcf.gz", $1 }' chromosomes.txt)
    gatk --java-options "-Xmx!{task.memory.toGiga()}g" GatherVcfs $gather_args -O !{meta.id}.g.vcf.gz
    tabix -p vcf !{meta.id}.g.vcf.gz
    '''
}

process GATK_COMBINEGVCFS {
    label 'sc_medium'
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
    label 'sc_medium'
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