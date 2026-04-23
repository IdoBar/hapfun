process FREEBAYES_SPLIT_REGIONS {
    label 'process_low'
    input:
        path ref_idx
    output:
        path "regions/*.regions.txt", emit: regions
    shell:
    '''
    mkdir -p regions
    awk '{ printf "%s %s\n", $1, $2 }' !{ref_idx} | while read -r chrom length; do
        printf '%s\n' "${chrom}:1-${length}" > "regions/${chrom}.regions.txt"
    done
    '''
}