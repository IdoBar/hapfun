process VCF_FILTER {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::bcftools=1.23.1"
    container 'quay.io/biocontainers/bcftools:1.23.1--hb2cee57_0'
    input: tuple val(meta), path(vcf)
    output:
        tuple val(meta), path("${meta.id}.Q${params.filter_qual}.poly.vcf.gz"), emit: filtered_vcf
        tuple val(meta), path("${meta.id}.snps.Q${params.filter_qual}.poly.vcf.gz"), emit: snps_vcf
        tuple val(meta), path("${meta.id}.indels.Q${params.filter_qual}.poly.vcf.gz"), emit: indels_vcf
    script:
    """
    bcftools filter -S . -e "GT=='het' || FMT/DP<${params.filter_ind_dp}" $vcf | \
    bcftools +fill-tags -- -t AN,AC,AF,F_MISSING | \
    bcftools view -i "QUAL>=${params.filter_qual} && INFO/DP>=${params.filter_min_dp} && INFO/DP<=${params.filter_max_dp} && COUNT(GT='ref')>=1 && COUNT(GT='alt')>=1" \
    -O z -o ${meta.id}.Q${params.filter_qual}.poly.vcf.gz
    
    bcftools index ${meta.id}.Q${params.filter_qual}.poly.vcf.gz

    bcftools view -v snps -i "QUAL>=${params.filter_qual}" \
    ${meta.id}.Q${params.filter_qual}.poly.vcf.gz | \
    bcftools +fill-tags -- -t AN,AC,AF \
    -O z -o ${meta.id}.snps.Q${params.filter_qual}.poly.vcf.gz
    
    bcftools index ${meta.id}.snps.Q${params.filter_qual}.poly.vcf.gz

    bcftools view -v indels -i "QUAL>=${params.filter_qual}" \
    ${meta.id}.Q${params.filter_qual}.poly.vcf.gz | \
    bcftools +fill-tags -- -t AN,AC,AF \
    -O z -o ${meta.id}.indels.Q${params.filter_qual}.poly.vcf.gz
    
    bcftools index ${meta.id}.indels.Q${params.filter_qual}.poly.vcf.gz
    """
}
