include { FASTP } from '../modules/local/qc_tools'
include { BWA_ALIGN } from '../modules/local/aligners'
include { SAMTOOLS_MERGE; MARK_DUPLICATES } from '../modules/local/bam_tools'
include { FREEBAYES_POPULATION; FREEBAYES } from '../modules/local/variant_callers'
include { BCFTOOLS_MERGE } from '../modules/local/vcf_tools'
include { MULTIQC } from '../modules/local/multiqc'
include { VCF_FILTER } from '../modules/local/vcf_filter'
include { BCFTOOLS_STATS as BCFTOOLS_STATS_RAW; BCFTOOLS_STATS as BCFTOOLS_STATS_FILTERED } from '../modules/local/vcf_tools'

workflow HAPFUN {
    ch_multiqc_reports = Channel.empty()
    
    // Create nf-core compliant channel with meta map
    ch_input = Channel.fromPath(params.input).splitCsv(header:true).map { row -> 
        def meta = [ id: row.sample, library: row.library, single_end: false ]
        tuple(meta, [file(row.fq1), file(row.fq2)]) 
    }
    
    ch_ref = file(params.ref)
    
    // --- STEP 1: QC ---
    FASTP(ch_input)
    ch_reads = FASTP.out.trimmed_reads
    ch_multiqc_reports = ch_multiqc_reports.mix(FASTP.out.json)
    

    // --- STEP 2: ALIGNMENT ---
    BWA_ALIGN(ch_reads, ch_ref)
    ch_bams = BWA_ALIGN.out.bam 

    // Merge BAMs by Sample ID (ignoring library)
    ch_for_merge = ch_bams.map { meta, bam -> 
        def new_meta = [ id: meta.id ]
        tuple(new_meta, bam) 
    }.groupTuple()
    
    SAMTOOLS_MERGE(ch_for_merge)
    MARK_DUPLICATES(SAMTOOLS_MERGE.out.merged_bam)
    ch_multiqc_reports = ch_multiqc_reports.mix(MARK_DUPLICATES.out.metrics)

    // --- STEP 3: VARIANT CALLING ---
    ch_ref_fai = file("${params.ref}.fai")
    ch_final_vcf = Channel.empty()

    if (params.freebayes_mode == 'population') {
        ch_all_bams = MARK_DUPLICATES.out.dedup_bam.map{ it[1] }.collect()
        ch_all_bais = MARK_DUPLICATES.out.dedup_bam.map{ it[2] }.collect()
        FREEBAYES_POPULATION(ch_all_bams, ch_all_bais, ch_ref, ch_ref_fai)
        ch_final_vcf = FREEBAYES_POPULATION.out.vcf.map { vcf -> tuple([id: "population"], vcf) }
    } else {
        FREEBAYES(MARK_DUPLICATES.out.dedup_bam, ch_ref, ch_ref_fai)
        BCFTOOLS_MERGE(FREEBAYES.out.vcf.collect(), FREEBAYES.out.csi.collect())
        ch_final_vcf = BCFTOOLS_MERGE.out.vcf.map { vcf -> tuple([id: "merged"], vcf) }
    }

    // --- STEP 4: FILTERING & METRICS ---
    BCFTOOLS_STATS_RAW(ch_final_vcf)
    ch_multiqc_reports = ch_multiqc_reports.mix(BCFTOOLS_STATS_RAW.out.stats)

    VCF_FILTER(ch_final_vcf)
    ch_filtered_vcf = VCF_FILTER.out.filtered_vcf.map { meta, vcf -> tuple([id: "${meta.id}_filtered"], vcf) }

    BCFTOOLS_STATS_FILTERED(ch_filtered_vcf)
    ch_multiqc_reports = ch_multiqc_reports.mix(BCFTOOLS_STATS_FILTERED.out.stats)
    
    // --- STEP 5: MULTIQC ---
    custom_runName = params.name
    if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
        custom_runName = workflow.runName
    }
    Channel.fromPath(params.multiqc_config, checkIfExists: true).set { ch_config_for_multiqc }
    MULTIQC(ch_multiqc_reports.collect(), ch_config_for_multiqc)
}
