process FREEBAYES_SPLIT_REGIONS {
    label 'process_low'
    input:
        path ref_idx
    output:
        path "regions/*.regions.txt", emit: regions
    shell:
    '''
    mkdir -p regions
    awk '{printf "%s:1-%s\\n", $1, $2 > ("regions/" $1 ".regions.txt")}' !{ref_idx}
    '''
}