include { FASTP; FASTQC; TRIMMOMATIC } from '../modules/local/qc_tools'
include { BWA_ALIGN; BOWTIE2_ALIGN } from '../modules/local/aligners'
include { SAMTOOLS_FAIDX; GATK_DICTIONARY; BWA_INDEX; BOWTIE2_INDEX } from '../modules/local/reference_prep'
include { GFF_TO_BED } from '../modules/local/annotation_prep'
include { SAMTOOLS_MERGE; MARK_DUPLICATES; QUALIMAP } from '../modules/local/bam_tools'
include { FREEBAYES_POPULATION; FREEBAYES; GATK_HAPLOTYPECALLER } from '../modules/local/variant_callers'
include { BCFTOOLS_MERGE } from '../modules/local/vcf_tools'
include { MULTIQC } from '../modules/local/multiqc'
include { MARK_DUPLICATES_LIB; GATK_CALL_LIB; FREEBAYES_CALL_LIB; VCF_MULTI_COMPARE } from '../modules/local/error_tools'
include { VCF_FILTER } from '../modules/local/vcf_filter'
include { BCFTOOLS_STATS as BCFTOOLS_STATS_RAW; BCFTOOLS_STATS as BCFTOOLS_STATS_FILTERED } from '../modules/local/vcf_tools'

workflow HAPFUN {
    ch_multiqc_reports = Channel.empty()
    
    // 1. INPUT PARSING
    ch_input = Channel.fromPath(params.input).splitCsv(header:true).map { row -> 
        def meta = [ id: row.sample, library: row.library, single_end: false ]
        tuple(meta, [file(row.fq1), file(row.fq2)]) 
    }
    
    ch_ref = file(params.ref)
    def ref_prefix = ch_ref.name

    // 2. PREPARE GENOME INDICES
    def fai_path = "${params.ref}.fai"
    if (file(fai_path).exists()) { ch_ref_fai = Channel.fromPath(fai_path).first() } 
    else { SAMTOOLS_FAIDX(ch_ref); ch_ref_fai = SAMTOOLS_FAIDX.out.fai.first() }

    def dict_path = "${params.ref.replaceAll(/\.fa(sta)?$/, '')}.dict"
    if (file(dict_path).exists()) { ch_ref_dict = Channel.fromPath(dict_path).first() } 
    else { GATK_DICTIONARY(ch_ref); ch_ref_dict = GATK_DICTIONARY.out.dict.first() }

    if (params.aligner == 'bwa-mem2') {
        if (params.bwa_index && file(params.bwa_index).exists()) { ch_align_index = Channel.fromPath(params.bwa_index).first() } 
        else { BWA_INDEX(ch_ref); ch_align_index = BWA_INDEX.out.index.first() }
    } else {
        if (params.bowtie2_index && file(params.bowtie2_index).exists()) { ch_align_index = Channel.fromPath(params.bowtie2_index).first() } 
        else { BOWTIE2_INDEX(ch_ref); ch_align_index = BOWTIE2_INDEX.out.index.first() }
    }

    // 3. PREPARE ANNOTATION (For Qualimap)
    if (params.annotation) {
        if (params.annotation.endsWith('.gff') || params.annotation.endsWith('.gff3')) {
            GFF_TO_BED(file(params.annotation))
            ch_annot_bed = GFF_TO_BED.out.bed.first()
        } else if (params.annotation.endsWith('.bed')) {
            ch_annot_bed = Channel.fromPath(params.annotation).first()
        } else { error "Annotation file must be .gff, .gff3, or .bed format" }
    } else { ch_annot_bed = Channel.value([]) }

    // --- STEP 1: QC ---
    if (params.trimmer == 'fastp') {
        FASTP(ch_input)
        ch_reads = FASTP.out.trimmed_reads
        ch_multiqc_reports = ch_multiqc_reports.mix(FASTP.out.json.map { meta, file -> file })
    } 
    else if (params.trimmer == 'trimmomatic') {
        FASTQC(ch_input)
        ch_multiqc_reports = ch_multiqc_reports.mix(FASTQC.out.results.map { meta, files -> files })

        TRIMMOMATIC(ch_input)
        ch_reads = TRIMMOMATIC.out.trimmed_reads
        ch_multiqc_reports = ch_multiqc_reports.mix(TRIMMOMATIC.out.log.map { meta, log -> log })
    } else { ch_reads = ch_input }

    if (params.stop_at == 'qc') { return }

    // --- STEP 2: ALIGNMENT ---
    if (params.aligner == 'bwa-mem2') {
        BWA_ALIGN(ch_reads, ch_align_index, ref_prefix)
        ch_bams = BWA_ALIGN.out.bam 
    } else {
        BOWTIE2_ALIGN(ch_reads, ch_align_index, ref_prefix)
        ch_bams = BOWTIE2_ALIGN.out.bam 
    }

    // =========================================================
    // BRANCH A: ERROR ESTIMATION (Per-Library Processing)
    // =========================================================
    if (params.error_estimate) {
        
        // Isolate samples with >1 library by temporarily pulling 'meta.id' to the front as the grouping key
        ch_multi_libs = ch_bams
            .map { meta, bam -> tuple(meta.id, meta, bam) }
            .groupTuple(by: 0)
            .filter { id, metas, bams -> bams.size() > 1 }
            .flatMap { id, metas, bams -> 
                // Unpack back into standard [meta, bam] streams
                def result = []
                for (int i = 0; i < metas.size(); i++) { result.add(tuple(metas[i], bams[i])) }
                return result
            }
        
        MARK_DUPLICATES_LIB(ch_multi_libs)

        if (params.caller == 'gatk') {
            GATK_CALL_LIB(MARK_DUPLICATES_LIB.out.dedup_bam, ch_ref, ch_ref_fai, ch_ref_dict)
            ch_lib_vcfs = GATK_CALL_LIB.out.vcf
        } else {
            FREEBAYES_CALL_LIB(MARK_DUPLICATES_LIB.out.dedup_bam, ch_ref, ch_ref_fai)
            ch_lib_vcfs = FREEBAYES_CALL_LIB.out.vcf
        }

        // Group VCFs by sample ID for the multi-compare script
        ch_vcfs_to_compare = ch_lib_vcfs
            .map { meta, vcf, idx -> tuple(meta.id, vcf, idx) }
            .groupTuple(by: 0)
            .map { id, vcfs, idxs -> tuple([id: id], vcfs, idxs) }

        VCF_MULTI_COMPARE(ch_vcfs_to_compare)
    }

    // =========================================================
    // BRANCH B: STANDARD WORKFLOW (Merged Processing)
    // =========================================================
    
    // Merge BAMs by creating a new meta map containing ONLY the sample ID
    ch_for_merge = ch_bams.map { meta, bam -> 
        def new_meta = [ id: meta.id ]
        tuple(new_meta, bam) 
    }.groupTuple()
    
    SAMTOOLS_MERGE(ch_for_merge)
    MARK_DUPLICATES(SAMTOOLS_MERGE.out.merged_bam)
    ch_multiqc_reports = ch_multiqc_reports.mix(MARK_DUPLICATES.out.metrics.map { meta, file -> file })
    
    QUALIMAP(MARK_DUPLICATES.out.dedup_bam, ch_annot_bed.ifEmpty([]))
    // Note: Use .results if your module emits tuple(meta, dir), or .report if it emits path(dir)
    ch_multiqc_reports = ch_multiqc_reports.mix(QUALIMAP.out.results.map { meta, dir -> dir })

    if (params.stop_at == 'alignment') { return }

    // --- STEP 3: VARIANT CALLING ---
    ch_final_vcf = Channel.empty()

    if (params.caller == 'freebayes' && params.freebayes_mode == 'population') {
        ch_all_bams = MARK_DUPLICATES.out.dedup_bam.map{ it[1] }.collect()
        ch_all_bais = MARK_DUPLICATES.out.dedup_bam.map{ it[2] }.collect()
        FREEBAYES_POPULATION(ch_all_bams, ch_all_bais, ch_ref, ch_ref_fai)
        ch_final_vcf = FREEBAYES_POPULATION.out.vcf.map { vcf -> tuple([id: "population"], vcf) }
    } else {
        if (params.caller == 'gatk') {
            GATK_HAPLOTYPECALLER(MARK_DUPLICATES.out.dedup_bam, ch_ref, ch_ref_fai, ch_ref_dict)
            ch_vcfs = GATK_HAPLOTYPECALLER.out.vcf
            ch_tbis = GATK_HAPLOTYPECALLER.out.tbi
        } else {
            FREEBAYES(MARK_DUPLICATES.out.dedup_bam, ch_ref, ch_ref_fai)
            ch_vcfs = FREEBAYES.out.vcf
            ch_tbis = FREEBAYES.out.csi
        }
        BCFTOOLS_MERGE(ch_vcfs.collect(), ch_tbis.collect())
        ch_final_vcf = BCFTOOLS_MERGE.out.vcf.map { vcf -> tuple([id: "merged"], vcf) }
    }

    // --- STEP 4: FILTERING & METRICS ---
    BCFTOOLS_STATS_RAW(ch_final_vcf)
    ch_multiqc_reports = ch_multiqc_reports.mix(BCFTOOLS_STATS_RAW.out.stats.map { meta, file -> file })

    VCF_FILTER(ch_final_vcf)
    ch_filtered_vcf = VCF_FILTER.out.filtered_vcf.map { meta, vcf -> tuple([id: "${meta.id}_filtered"], vcf) }

    BCFTOOLS_STATS_FILTERED(ch_filtered_vcf)
    ch_multiqc_reports = ch_multiqc_reports.mix(BCFTOOLS_STATS_FILTERED.out.stats.map { meta, file -> file })
    
    // --- FINAL STEP: MULTIQC ---
    MULTIQC(ch_multiqc_reports.collect())
}