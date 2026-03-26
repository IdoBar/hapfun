# HapFun: Haploid Fungal SNP Calling Pipeline
<!-- 
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](https://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/) -->
[![Repo](https://img.shields.io/badge/GitHub-IdoBar%2Fhapfun-181717?logo=github)](https://github.com/IdoBar/hapfun)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg?labelColor=000000&logo=data:image/svg%2bxml;base64,PHN2ZyB3aWR0aD0iMjUxIiBoZWlnaHQ9IjI1MiIgdmlld0JveD0iMCAwIDI1MSAyNTIiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+DQo8cGF0aCBkPSJNMCA0Ny42MzQ1QzM5LjQ1IDUwLjI1NDMgNzEuMDYgODEuOTQyMiA3My41NCAxMjEuNDNIMTE5LjYxQzExNy4wNSA1Ni40NzM5IDY0LjkzIDQuMjU3NDQgMCAxLjU1NzYyVjQ3LjYzNDVaIiBmaWxsPSIjMjJBRTYzIi8+DQo8cGF0aCBkPSJNNzMuOCAxMzEuOTM5QzcxLjE4IDE3MS4zODYgMzkuNDkgMjAyLjk5NCAwIDIwNS40NzRWMjUxLjU0MUM2NC45NiAyNDguOTgxIDExNy4xOCAxOTYuODY1IDExOS44OCAxMzEuOTM5SDczLjhaIiBmaWxsPSIjMjJBRTYzIi8+DQo8cGF0aCBkPSJNMTc2LjIwMSAxMjEuMTZDMTc4LjgyMSA4MS43MTIyIDIxMC41MTEgNTAuMTA0MyAyNTAuMDAxIDQ3LjYyNDVWMS41NTc2MkMxODUuMDQxIDQuMTE3NDQgMTMyLjgyMSA1Ni4yMzM5IDEzMC4xMjEgMTIxLjE2SDE3Ni4yMDFaIiBmaWxsPSIjMjJBRTYzIi8+DQo8cGF0aCBkPSJNMjUwLjAwMSAyMDUuNDY0QzIxMC41NTEgMjAyLjg0NSAxNzguOTQxIDE3MS4xNTcgMTc2LjQ2MSAxMzEuNjY5SDEzMC4zOTFDMTMyLjk1MSAxOTYuNjI1IDE4NS4wNzEgMjQ4Ljg0MiAyNTAuMDAxIDI1MS41NDFWMjA1LjQ2NFoiIGZpbGw9IiMyMkFFNjMiLz4NCjwvc3ZnPg==)](https://www.nextflow.io/)
[![run with conda](https://img.shields.io/badge/run%20with-conda-3EB049.svg?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed.svg?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with apptainer/singularity](https://img.shields.io/badge/run%20with-apptainer%2Fsingularity-F48B11.svg?labelColor=000000&logo=data:image/svg%2bxml;base64,PHN2ZyB3aWR0aD0iMjQ1IiBoZWlnaHQ9IjI0MCIgdmlld0JveD0iNjAgMCAzMTAgMjUwIiBmaWxsPSJub25lIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgk8cGF0aCBkPSJtIDI3MC4xOCwyNTMuOTggYyAtMS44LC0xLjIgLTMuNCwtMyAtNC40LC01LjIgbCAtNTIuNiwtMTE3LjQgYyAtMi4yLC00LjggLTMuOCwtOC42IC01LjIsLTExLjYgLTIuMiwtNC40IC0yLjIsLTUuNiAtMi4yLC02LjQgMCwtMi4yIDAuOCwtMy44IDIuNiwtNC44IHYgLTQuNCBoIC00My4yIHYgNC40IGMgMC44LDAuNCAxLjIsMS4yIDEuOCwxLjggMC40LDAuOCAwLjgsMS44IDAuOCwzIDAsMS4yIC0wLjQsMyAtMS44LDUuNiAtMS4yLDIuNiAtMi42LDUuNiAtNC40LDkuNCBsIC01MS44LDExNyBjIC0wLjgsMS44IC0yLjIsNC40IC0zLjgsNy40IC0xLjgsMyAtNC44LDQuNCAtOC4yLDQuOCB2IDMuOCBoIDQ5LjYgdiAtMy44IGMgLTUuNiwwIC04LjIsLTIuMiAtOC4yLC01LjYgMCwtMS44IDAuOCwtNC44IDMsLTkgMS44LC0zLjQgMy44LC03LjggNS42LC0xMiAyNC42LDkuNCA1Mi4yLDEwIDc2LjgsMC44IDIuMiw0LjQgMy44LDguMiA1LjIsMTEuMiAxLjgsMy40IDIuNiw2LjQgMi42LDguNiAwLDIuMiAtMC44LDMuOCAtMi4yLDQuOCAtMS4yLDAuNCAtMi4yLDAuOCAtMy40LDEuMiB2IDMuOCBoIDUwLjQgdiAtMy44IGMgLTIuOCwtMS44IC01LjQsLTIuOCAtNywtMy42IHogbSAtMTExLjQsLTQ3IDI3LjYsLTYxLjQgMjgsNjIuMiBjIC0xOCw2IC0zNy40LDYgLTU1LjYsLTAuOCB6IiBmaWxsPSJ3aGl0ZSIvPiA8cGF0aCBkPSJtIDg5Ljc4LDE0MC45OCBjIDAsLTkgMS4yLC0xNy42IDMuNCwtMjYuNCBsIC0yOCwtMTIuNiBjIC0zLjgsMTIgLTYsMjQuNiAtNiwzNy42IDAsMzUgMTQuMiw2OC42IDM5LjgsOTIuOCBsIDEuOCwtMy40IDExLjIsLTI1LjQgYyAtMTMuNiwtMTcuNCAtMjIuMiwtMzkgLTIyLjIsLTYyLjYgeiIgZmlsbD0iIzkzOTU5OCIvPiA8cGF0aCBkPSJtIDMxMC4xOCwxMDIuNTggLTI4LDEyLjYgYyAyLjIsOC4yIDMuNCwxNi44IDMuNCwyNS44IDAsMjMuOCAtOC42LDQ1LjggLTIyLjgsNjIuNiBsIDExLjYsMjUuNCAxLjgsMy40IGMgMjUuNCwtMjQuMiAzOS44LC01Ny44IDM5LjgsLTkyLjggLTAuMiwtMTIuNCAtMi4yLC0yNSAtNS44LC0zNyB6IiBmaWxsPSIjRjc5NDIxIi8+IDxwYXRoIGQ9Im0gNzEuMTgsODYuOTggMjcuNiwxMi42IGMgMTQuNiwtMzEgNDQuOCwtNTMgODAuMiwtNTYuMiB2IC0zMC42IGMgLTQ2LDIuNiAtODguNCwzMS40IC0xMDcuOCw3NC4yIHoiIGZpbGw9IiMxRTk1RDMiLz4gPHBhdGggZD0ibSAzMDQuMTgsODYuOTggYyAtMTkuNCwtNDIuOCAtNjEuOCwtNzEuNiAtMTA4LjQsLTc0LjYgdiAzMC42IGMgMzUuOCwzIDY2LDI1IDgwLjYsNTYuMiB6IiBmaWxsPSIjNkZCNTQ0Ii8+PC9zdmc+)](https://sylabs.io/docs/)
<!-- [![Container support](https://img.shields.io/badge/Containers-Docker%20%7C%20Singularity-0db7ed)](https://www.nextflow.io/docs/latest/container.html) -->

HapFun is a Nextflow DSL2 pipeline for calling and filtering SNPs from paired-end short-read sequencing data of clonal haploid fungal isolates.

## Pipeline Overview

The workflow takes paired-end short-read sequencing data and performs the following:

- Read quality control and trimming with `fastp` or `Trimmomatic` and `fastQC`
- Aligns trimmed reads to the reference genome with `bwa-mem2` or `bowtie2`  
- Merges libraries per sample and marks duplicates with `samtools`, `GATK MarkDuplicates`
- Calls variants with `freebayes` or `GATK`:
  - `population` mode (with `Freebayes` only): one combined call across all samples
  - `individual` mode: one call per sample, then merge
- Filters variants using quality/depth and haploid-specific genotype logic
- Generates raw and filtered VCF statistics and a MultiQC report

Optional step:

- Assesses genotype call error rates between replicated libraries of the same sample

## Requirements

- Nextflow (recommended: latest stable)
- One execution backend profile:
  - `-profile conda`
  - `-profile docker`
  - `-profile singularity`
  - `-profile apptainer`

### Required Inputs

1. Samplesheet CSV (`--input`)
2. Reference FASTA (`--ref`)
3. Reference index file at `${ref}.fai` (must exist before run)

## Samplesheet Format

Input reads are provided through a samplesheet (CSV with header), where each row links a sample/library pair to two FASTQ files (see example below):

```csv
sample,library,fq1,fq2
sample01,libA,/path/to/sample01_libA_R1.fastq.gz,/path/to/sample01_libA_R2.fastq.gz
sample01,libB,/path/to/sample01_libB_R1.fastq.gz,/path/to/sample01_libB_R2.fastq.gz
sample02,libA,/path/to/sample02_libA_R1.fastq.gz,/path/to/sample02_libA_R2.fastq.gz
```

Notes:

- Multiple rows can share the same `sample` with different `library` values.
- Libraries belonging to the same sample are merged at BAM level before variant calling.
- Inputs are treated as paired-end reads.

## Quick Start

Run with conda:

```bash
nextflow run main.nf \
  -profile conda \
  --input assets/samplesheet.csv \
  --ref data/ref.fa \
  --outdir results
```

Run with Docker:

```bash
nextflow run main.nf \
  -profile docker \
  --input assets/samplesheet.csv \
  --ref data/ref.fa \
  --outdir results
```

Run with Singularity:

```bash
nextflow run main.nf \
  -profile singularity \
  --input assets/samplesheet.csv \
  --ref data/ref.fa \
  --outdir results
```

## Minimal Test Dataset (Smoke Test)

For a quick functional test, run the pipeline on a very small paired-end dataset (for example, one isolate with a few thousand reads per mate).

1. Prepare a tiny test directory with one pair of FASTQ files and a matching reference FASTA.
2. Create a minimal samplesheet (for example `assets/samplesheet_test.csv`):

```csv
sample,library,fq1,fq2
test01,libA,/absolute/path/to/test01_R1.fastq.gz,/absolute/path/to/test01_R2.fastq.gz
```

3. Ensure the reference index exists:

```bash
samtools faidx /absolute/path/to/test_ref.fa
```

4. Run a smoke test:

```bash
nextflow run main.nf \
  -profile conda \
  --input assets/samplesheet_test.csv \
  --ref /absolute/path/to/test_ref.fa \
  --outdir results_test \
  -resume
```

Expected outcome: completion without process failures and creation of `results_test/multiqc/` plus filtered VCF outputs in `results_test/variants/filtered/`.

## Key Parameters

Input/output:

- `--input` (default: `assets/samplesheet.csv`)
- `--ref` (default: `data/ref.fa`)
- `--outdir` (default: `results`)

Variant calling mode:

- `--freebayes_mode population|individual` (default: `population`)

Filtering thresholds:

- `--filter_qual` (default: `30`)
- `--filter_min_dp` (default: `10`)
- `--filter_max_dp` (default: `100000`)
- `--filter_ind_dp` (default: `7`)

Tool argument passthrough:

- `--fastp_args`
- `--bwa_args`
- `--freebayes_args`

MultiQC config:

- `--multiqc_config` (default: `assets/multiqc_config.yaml`)

## Main Outputs

By default, outputs are written to `results/`:

- `results/qc/fastp/` - `fastp` reports
- `results/aligned/` - duplicate-marked BAMs and metrics
- `results/variants/population/` or `results/variants/individual/` - FreeBayes VCFs
- `results/variants/merged/` - merged VCF (individual mode)
- `results/variants/filtered/` - filtered, SNP-only, and indel-only VCFs
- `results/qc/bcftools/` - raw and filtered VCF stats
- `results/multiqc/` - MultiQC report

## Reproducibility Tips

- Keep the same profile and software stack across runs.
- Store the exact command line and commit hash used for each analysis.
- Use `-resume` to continue interrupted runs reproducibly.

## Acknowledgement

This pipeline follows nf-core style channel conventions (meta maps and tuple channels) while being customized for haploid fungal variant discovery.
