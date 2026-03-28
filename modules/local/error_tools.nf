// Save as: modules/local/error_tools.nf

process MARK_DUPLICATES_LIB {
    tag "${meta.id}_${meta.library}"
    label 'process_medium'
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.dedup.bam"), path("*.dedup.bai"), emit: dedup_bam
    path "*.metrics.txt", emit: metrics

    script:
    """
    gatk MarkDuplicates \\
        -I $bam \\
        -O ${meta.id}_${meta.library}.dedup.bam \\
        -M ${meta.id}_${meta.library}.metrics.txt \\
        --CREATE_INDEX true \\
        --READ_NAME_REGEX null
    """
}

process GATK_CALL_LIB {
    tag "${meta.id}_${meta.library}"
    label 'process_medium'
    conda "bioconda::gatk4=4.6.2.0"
    container 'broadinstitute/gatk:4.6.2.0'

    input:
    tuple val(meta), path(bam), path(bai)
    path ref
    path ref_idx 
    path ref_dict 

    output:
    tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: vcf

    script:
    """
    gatk --java-options "-Xmx${task.memory.toGiga()}g" HaplotypeCaller \\
        -R $ref \\
        -I $bam \\
        -O ${meta.id}_${meta.library}.vcf.gz \\
        -ploidy ${params.ploidy}
    """
}

process FREEBAYES_CALL_LIB {
    tag "${meta.id}_${meta.library}"
    label 'process_medium'
    conda "bioconda::freebayes=1.3.10"
    container 'quay.io/biocontainers/freebayes:1.3.10--hbefcdb2_0'

    input:
    tuple val(meta), path(bam), path(bai)
    path ref
    path ref_idx

    output:
    tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: vcf

    script:
    """
    freebayes -f $ref -p ${params.ploidy} $bam | bgzip > ${meta.id}_${meta.library}.vcf.gz
    tabix ${meta.id}_${meta.library}.vcf.gz
    """
}

process VCF_MULTI_COMPARE {
    tag "$meta.id"
    label 'process_low'
    conda "conda-forge::python=3.9 conda-forge::pandas=1.4.2 bioconda::pysam=0.19.1"
    container 'quay.io/biocontainers/mulled-v2-629aec3ba267b06a1efc3ec454c0f09e134f6ee2:3b083bb5eae6e491b8579589b070fa29afbea2a1-0'

    input:
    tuple val(meta), val(compare_label), path(vcfs), path(indexes)
    path compare_script

    output:
    path "${meta.id}_${compare_label}_discordance.csv", emit: report

    script:
    def vcf_args = vcfs.collect { "'${it}'" }.join(' ')
    """
    python $compare_script \\
        --vcfs ${vcf_args} \\
        --sample ${meta.id} \\
        --out ${meta.id}_${compare_label}_discordance.csv
    """
}

process VCF_DISCORDANCE_MQC {
    label 'process_low'
    conda "conda-forge::python=3.9 conda-forge::pandas=1.4.2"
    container 'quay.io/biocontainers/mulled-v2-629aec3ba267b06a1efc3ec454c0f09e134f6ee2:3b083bb5eae6e491b8579589b070fa29afbea2a1-0'

    input:
    path discordance_csvs

    output:
    path "hapfun_discordance_rate_mqc.csv", emit: mqc_rate_csv
    path "hapfun_discordance_metrics_mqc.csv", emit: mqc_metrics_csv

    script:
    """
    python - << 'PY'
from pathlib import Path

import pandas as pd

sample_values = {}
metric_cols = ['shared_sites', 'concordant', 'discordant', 'discordance_rate']

for p in Path('.').glob('*_discordance.csv'):
    stem = p.name[:-len('_discordance.csv')]
    if '_' not in stem:
        continue

    sample_id, phase = stem.rsplit('_', 1)
    if phase not in ('raw', 'filtered'):
        continue

    df = pd.read_csv(p)

    phase_stats = {}
    for col in metric_cols:
        if col in df.columns and len(df) > 0:
            vals = pd.to_numeric(df[col], errors='coerce').dropna()
            phase_stats[col] = float(vals.mean()) if len(vals) > 0 else 0.0
        else:
            phase_stats[col] = 0.0

    sample_values.setdefault(sample_id, {})[phase] = phase_stats

for sample_id in sample_values:
    sample_values[sample_id].setdefault('raw', {col: 0.0 for col in metric_cols})
    sample_values[sample_id].setdefault('filtered', {col: 0.0 for col in metric_cols})

rate_header = '''# id: 'hapfun_discordance_rate'
# section_name: 'Library Discordance Before vs After Filtering'
# description: 'Mean pairwise genotype discordance rate per sample, comparing raw and filtered variant calls.'
# plot_type: 'bargraph'
# pconfig:
#   id: 'hapfun_discordance_rate_plot'
#   title: 'Discordance Before vs After Filtering'
#   ylab: 'Discordance rate'
#   xlab: 'Sample'
'''

rate_rows = ["Sample,Raw,Filtered"]
for sample_id, vals in sorted(sample_values.items()):
    rate_rows.append(
        f"{sample_id},{round(vals['raw']['discordance_rate'], 6)},{round(vals['filtered']['discordance_rate'], 6)}"
    )

metrics_header = '''# id: 'hapfun_discordance_metrics'
# section_name: 'Library Discordance Metrics (Raw vs Filtered)'
# description: 'Mean pairwise shared sites, concordant sites, discordant sites, and discordance rate per sample for raw and filtered calls.'
# plot_type: 'table'
# pconfig:
#   id: 'hapfun_discordance_metrics_table'
#   title: 'Library Discordance Metrics (Raw vs Filtered)'
'''

metrics_rows = [
    "Sample,raw_shared_sites,raw_concordant,raw_discordant,raw_discordance_rate,filtered_shared_sites,filtered_concordant,filtered_discordant,filtered_discordance_rate"
]
for sample_id, vals in sorted(sample_values.items()):
    metrics_rows.append(
        f"{sample_id},"
        f"{round(vals['raw']['shared_sites'], 6)},{round(vals['raw']['concordant'], 6)},{round(vals['raw']['discordant'], 6)},{round(vals['raw']['discordance_rate'], 6)},"
        f"{round(vals['filtered']['shared_sites'], 6)},{round(vals['filtered']['concordant'], 6)},{round(vals['filtered']['discordant'], 6)},{round(vals['filtered']['discordance_rate'], 6)}"
    )

nl = chr(10)
with open('hapfun_discordance_rate_mqc.csv', 'w') as fh:
    fh.write(rate_header)
    fh.write(nl.join(rate_rows) + nl)

with open('hapfun_discordance_metrics_mqc.csv', 'w') as fh:
    fh.write(metrics_header)
    fh.write(nl.join(metrics_rows) + nl)
PY
    """
}