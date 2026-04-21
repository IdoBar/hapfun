process FREEBAYES_SPLIT_REGIONS {
    label 'process_low'
    input:
        path ref_idx
    output:
        path "regions/*.regions.txt", emit: regions
    script:
    """
    mkdir -p regions
    awk 'BEGIN { counter = 0 } { counter += 1; printf "%06d__%s\t%s\n", counter, \$1, \$2 }' $ref_idx | while IFS=$'\t' read -r chrom_label length; do
        chrom="${chrom_label#*__}"
        printf '%s\n' "${chrom}:1-${length}" > "regions/${chrom_label}.regions.txt"
    done
    """
}