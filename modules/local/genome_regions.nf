process FREEBAYES_SPLIT_REGIONS {
    label 'process_low'
    input:
        path ref_idx
    output:
        path "regions/*.regions.txt", emit: regions
    shell:
    '''
    mkdir -p regions
    awk 'BEGIN { counter = 0 } { counter += 1; printf "%06d__%s %s %s\\n", counter, $1, $2, $1 }' !{ref_idx} | while read -r chrom_label length chrom; do
        printf '%s\\n' "${chrom}:1-${length}" > "regions/${chrom_label}.regions.txt"
    done
    '''
}