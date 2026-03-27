// Save as: modules/local/annotation_prep.nf

process GFF_TO_BED {
    tag "$gff"
    label 'process_low'
    conda "bioconda::bedops=2.4.41"
    container 'quay.io/biocontainers/bedops:2.4.41--h4ac6f70_2'

    input:
    path gff

    output:
    path "*.bed", emit: bed

    script:
    // Safely strip the extension and replace with .bed
    def bed_name = gff.name.replaceAll(/\.gff(3)?$/, ".bed")
    """
    gff2bed < $gff > $bed_name
    """
}