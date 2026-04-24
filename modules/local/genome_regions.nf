process FREEBAYES_SPLIT_REGIONS {
    label 'sc_small'
    conda "bioconda::freebayes=1.3.10"
    container 'quay.io/biocontainers/freebayes:1.3.10--hbefcdb2_0'
    input:
        path ref_idx
        val chunk_size
    output:
        path "regions/*.regions.txt", emit: regions
    script:
    def chunk = (chunk_size ?: 500000).toString().trim()
    """
    mkdir -p regions

    fasta_generate_regions.py ${ref_idx} ${chunk} > target_regions.txt

    cut -f1 ${ref_idx} | xargs -I{} sh -c '
        chrom="\$1"
        awk -v chr="\$chrom" -F "[:[:space:]]+" "\$1 == chr { print \$0 }" target_regions.txt > "regions/\${chrom}.regions.txt"
        if [ ! -s "regions/\${chrom}.regions.txt" ]; then
            awk -v chr="\$chrom" "\$1 == chr { printf \"%s:1-%s\\n\", \$1, \$2 }" ${ref_idx} > "regions/\${chrom}.regions.txt"
        fi
    ' _ {}
    """
}