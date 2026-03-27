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
    tuple val(meta), val(compare_label), path(vcfs)
    path compare_script

    output:
    path "${meta.id}_${compare_label}_discordance.csv", emit: report

    script:
    """
    python $compare_script \\
        --vcfs $vcfs \\
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
    path "discordance_before_after_mqc.json", emit: mqc_json

    script:
    """
    python - << 'PY'
import json
import re
from pathlib import Path

import pandas as pd

sample_values = {}

for p in Path('.').glob('*_discordance.csv'):
    m = re.match(r'(.+)_(raw|filtered)_discordance\\.csv\$', p.name)
    if not m:
        continue

    sample_id, phase = m.group(1), m.group(2)
    df = pd.read_csv(p)

    # Empty CSVs (e.g., <2 libraries) should still appear as 0.0 in the plot.
    if 'discordance_rate' in df.columns and len(df) > 0:
        value = float(df['discordance_rate'].mean())
    else:
        value = 0.0

    sample_values.setdefault(sample_id, {})[phase] = round(value, 6)

for sample_id in sample_values:
    sample_values[sample_id].setdefault('raw', 0.0)
    sample_values[sample_id].setdefault('filtered', 0.0)

mqc = {
    'id': 'hapfun_discordance_before_after',
    'section_name': 'Library Discordance Before vs After Filtering',
    'description': 'Mean pairwise library discordance rate per sample, comparing raw and filtered calls.',
    'plot_type': 'bargraph',
    'pconfig': {
        'id': 'hapfun_discordance_before_after_plot',
        'title': 'Discordance Before vs After Filtering',
        'ylab': 'Discordance rate (%)',
        'xlab': 'Sample',
        'categories': True
    },
    'data': sample_values
}

with open('discordance_before_after_mqc.json', 'w') as fh:
    json.dump(mqc, fh)
PY
    """
}