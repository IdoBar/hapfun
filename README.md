# HapFun: Haploid Fungal SNP Calling Pipeline
<!-- 
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](https://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/) -->
[![Repo](https://img.shields.io/badge/GitHub-IdoBar%2Fhapfun-181717?logo=github)](https://github.com/IdoBar/hapfun)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg?labelColor=000000&logo=data:image/svg%2bxml;base64,PHN2ZyB3aWR0aD0iMjUxIiBoZWlnaHQ9IjI1MiIgdmlld0JveD0iMCAwIDI1MSAyNTIiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+DQo8cGF0aCBkPSJNMCA0Ny42MzQ1QzM5LjQ1IDUwLjI1NDMgNzEuMDYgODEuOTQyMiA3My41NCAxMjEuNDNIMTE5LjYxQzExNy4wNSA1Ni40NzM5IDY0LjkzIDQuMjU3NDQgMCAxLjU1NzYyVjQ3LjYzNDVaIiBmaWxsPSIjMjJBRTYzIi8+DQo8cGF0aCBkPSJNNzMuOCAxMzEuOTM5QzcxLjE4IDE3MS4zODYgMzkuNDkgMjAyLjk5NCAwIDIwNS40NzRWMjUxLjU0MUM2NC45NiAyNDguOTgxIDExNy4xOCAxOTYuODY1IDExOS44OCAxMzEuOTM5SDczLjhaIiBmaWxsPSIjMjJBRTYzIi8+DQo8cGF0aCBkPSJNMTc2LjIwMSAxMjEuMTZDMTc4LjgyMSA4MS43MTIyIDIxMC41MTEgNTAuMTA0MyAyNTAuMDAxIDQ3LjYyNDVWMS41NTc2MkMxODUuMDQxIDQuMTE3NDQgMTMyLjgyMSA1Ni4yMzM5IDEzMC4xMjEgMTIxLjE2SDE3Ni4yMDFaIiBmaWxsPSIjMjJBRTYzIi8+DQo8cGF0aCBkPSJNMjUwLjAwMSAyMDUuNDY0QzIxMC41NTEgMjAyLjg0NSAxNzguOTQxIDE3MS4xNTcgMTc2LjQ2MSAxMzEuNjY5SDEzMC4zOTFDMTMyLjk1MSAxOTYuNjI1IDE4NS4wNzEgMjQ4Ljg0MiAyNTAuMDAxIDI1MS41NDFWMjA1LjQ2NFoiIGZpbGw9IiMyMkFFNjMiLz4NCjwvc3ZnPg==)](https://www.nextflow.io/)
[![run with conda](https://img.shields.io/badge/run%20with-conda-3EB049.svg?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed.svg?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity/apptainer](https://img.shields.io/badge/run%20with-singularity%2Fapptainer-F48B11.svg?labelColor=000000&logo=data:image/svg%2bxml;base64,PHN2ZyB3aWR0aD0iMjQ1IiBoZWlnaHQ9IjI0MCIgdmlld0JveD0iNjAgMCAzMTAgMjUwIiBmaWxsPSJub25lIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgk8cGF0aCBkPSJtIDI3MC4xOCwyNTMuOTggYyAtMS44LC0xLjIgLTMuNCwtMyAtNC40LC01LjIgbCAtNTIuNiwtMTE3LjQgYyAtMi4yLC00LjggLTMuOCwtOC42IC01LjIsLTExLjYgLTIuMiwtNC40IC0yLjIsLTUuNiAtMi4yLC02LjQgMCwtMi4yIDAuOCwtMy44IDIuNiwtNC44IHYgLTQuNCBoIC00My4yIHYgNC40IGMgMC44LDAuNCAxLjIsMS4yIDEuOCwxLjggMC40LDAuOCAwLjgsMS44IDAuOCwzIDAsMS4yIC0wLjQsMyAtMS44LDUuNiAtMS4yLDIuNiAtMi42LDUuNiAtNC40LDkuNCBsIC01MS44LDExNyBjIC0wLjgsMS44IC0yLjIsNC40IC0zLjgsNy40IC0xLjgsMyAtNC44LDQuNCAtOC4yLDQuOCB2IDMuOCBoIDQ5LjYgdiAtMy44IGMgLTUuNiwwIC04LjIsLTIuMiAtOC4yLC01LjYgMCwtMS44IDAuOCwtNC44IDMsLTkgMS44LC0zLjQgMy44LC03LjggNS42LC0xMiAyNC42LDkuNCA1Mi4yLDEwIDc2LjgsMC44IDIuMiw0LjQgMy44LDguMiA1LjIsMTEuMiAxLjgsMy40IDIuNiw2LjQgMi42LDguNiAwLDIuMiAtMC44LDMuOCAtMi4yLDQuOCAtMS4yLDAuNCAtMi4yLDAuOCAtMy40LDEuMiB2IDMuOCBoIDUwLjQgdiAtMy44IGMgLTIuOCwtMS44IC01LjQsLTIuOCAtNywtMy42IHogbSAtMTExLjQsLTQ3IDI3LjYsLTYxLjQgMjgsNjIuMiBjIC0xOCw2IC0zNy40LDYgLTU1LjYsLTAuOCB6IiBmaWxsPSJ3aGl0ZSIvPiA8cGF0aCBkPSJtIDg5Ljc4LDE0MC45OCBjIDAsLTkgMS4yLC0xNy42IDMuNCwtMjYuNCBsIC0yOCwtMTIuNiBjIC0zLjgsMTIgLTYsMjQuNiAtNiwzNy42IDAsMzUgMTQuMiw2OC42IDM5LjgsOTIuOCBsIDEuOCwtMy40IDExLjIsLTI1LjQgYyAtMTMuNiwtMTcuNCAtMjIuMiwtMzkgLTIyLjIsLTYyLjYgeiIgZmlsbD0iIzkzOTU5OCIvPiA8cGF0aCBkPSJtIDMxMC4xOCwxMDIuNTggLTI4LDEyLjYgYyAyLjIsOC4yIDMuNCwxNi44IDMuNCwyNS44IDAsMjMuOCAtOC42LDQ1LjggLTIyLjgsNjIuNiBsIDExLjYsMjUuNCAxLjgsMy40IGMgMjUuNCwtMjQuMiAzOS44LC01Ny44IDM5LjgsLTkyLjggLTAuMiwtMTIuNCAtMi4yLC0yNSAtNS44LC0zNyB6IiBmaWxsPSIjRjc5NDIxIi8+IDxwYXRoIGQ9Im0gNzEuMTgsODYuOTggMjcuNiwxMi42IGMgMTQuNiwtMzEgNDQuOCwtNTMgODAuMiwtNTYuMiB2IC0zMC42IGMgLTQ2LDIuNiAtODguNCwzMS40IC0xMDcuOCw3NC4yIHoiIGZpbGw9IiMxRTk1RDMiLz4gPHBhdGggZD0ibSAzMDQuMTgsODYuOTggYyAtMTkuNCwtNDIuOCAtNjEuOCwtNzEuNiAtMTA4LjQsLTc0LjYgdiAzMC42IGMgMzUuOCwzIDY2LDI1IDgwLjYsNTYuMiB6IiBmaWxsPSIjNkZCNTQ0Ii8+PC9zdmc+)](https://sylabs.io/docs/)

## Introduction

**HapFun** (Haploid Fungal SNP Calling) is a highly scalable bioinformatics pipeline for identifying single nucleotide polymorphisms (SNPs) and insertions/deletions (Indels) from whole-genome sequencing (WGS) data of clonal haploid fungal isolates.

Built using Nextflow DSL2 and strictly adhering to nf-core data structures (including meta maps), HapFun bridges the gap between raw sequencing reads and high-quality, filtered variant calls. It is highly parameterized, automatically handles missing reference indices, and includes a unique parallel track for estimating error rates across replicate libraries of same samples.

## Pipeline Summary

By default, **HapFun** performs the following steps:

1. **Reference Preparation**: Automatically decompresses the reference (if provided as `.fasta.gz`) and generates missing `.fai`, `.dict`, and aligner index directories (`bwa-mem2` or `bowtie2`) if not provided by the user.
2. **Read QC & Trimming**: `fastp` (default) OR `FastQC` + `Trimmomatic`.
3. **Read Alignment**: `bwa-mem2` (default) or `bowtie2`.
4. **BAM Processing**:
    * Merges multiple libraries belonging to the same sample (`samtools`).
    * Marks optical/PCR duplicates (`GATK MarkDuplicates`).
5. **Alignment QC**: `Qualimap` (Supports optional `.gff`/`.bed` annotations for targeted region metrics).
6. **Variant Calling**: `Freebayes` (Population mode default) or `GATK HaplotypeCaller`.
    * *Supports Freebayes population-level calling, or individual sample calling + merging.*
7. **Error Estimation (Optional)**: If `--error_estimate true` is flagged, the pipeline automatically separates replicate libraries, calls variants on them independently, and calculates genotype discordance rates using a custom Python module. The raw per-library VCFs used in this comparison are also retained in `results/variants/error_estimate_libraries/`.
8. **Population Genetics (Optional)**: If `--popgen true`, HapFun performs PCA (PC1-PC3) and constructs a phylogenetic tree from the final cohort VCF (regardless of variant caller and calling mode), then adds both panels to MultiQC. If a `pop` column is present in the samplesheet, it is used to color PCA markers and tree nodes.
9. **Variant Filtering**: Strictly filters VCFs based on Depth (DP), Quality (QUAL), and polymorphism, while recalculating INFO tags (`bcftools +fill-tags`). Outputs distinct `.snps.vcf` and `.indels.vcf` files.
10. **Final Reporting**: Aggregates QC metrics across all steps into a single HTML report (`MultiQC`).

## Quick Start

1. Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (>=22.10.1).
2. Install [Conda](https://docs.conda.io/en/latest/), [Docker](https://docs.docker.com/engine/installation/), or [Singularity/Apptainer](https://sylabs.io/guides/3.0/user-guide/).
   * *Note: Apptainer is only supported from Nextflow version 22.11.0-edge and later.*
3. Create a `samplesheet.csv` with your input data.
    * *Note: Rows with the exact same `sample` ID but different `library` IDs will be automatically merged post-alignment.*
    * *Optional: Add a `pop` column with population/group labels. This is used by the population genetics module to color PCA markers and phylogenetic tree nodes.*

    ```csv
        sample,library,pop,fq1,fq2
        FungusA,Lib1,Pop_1,data/A_L1_1.fq.gz,data/A_L1_2.fq.gz
        FungusA,Lib2,Pop_1,data/A_L2_1.fq.gz,data/A_L2_2.fq.gz
        FungusB,Lib1,Pop_2,data/B_L1_1.fq.gz,data/B_L1_2.fq.gz
    ```

4. Run the pipeline:

    ```bash
        nextflow run main.nf \
            -profile conda \
            --input samplesheet.csv \
            --ref data/reference.fa \
            --outdir results
    ```

    *Swap `-profile conda` with `-profile docker` or `-profile singularity` `-profile apptainer` depending on your environment.*

## Advanced Usage

HapFun allows you to bypass expensive indexing steps by providing pre-built directories, and allows fine-grained control over tool arguments.

**Example: Providing pre-built indices, annotations, and custom trimming arguments:**

```bash
    nextflow run main.nf \
        -profile docker \
        --input samplesheet.csv \
        --ref data/reference.fa \
        --bwa_index path/to/bwa_index/ \
        --annotation data/genes.gff \
        --trimmer trimmomatic \
        --trimmomatic_args "ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 LEADING:5 TRAILING:5 MINLEN:50" \
        --error_estimate true
```

### Key Parameters

**Inputs & References:**

* `--ref`: Path to reference FASTA.
* `--annotation`: (Optional) Path to `.gff`, `.gff3`, or `.bed` for targeted Qualimap QC.
* `--bwa_index`: (Optional) Path to pre-built BWA-mem2 index directory.
* `--bowtie2_index`: (Optional) Path to pre-built Bowtie2 index directory.

**Tool Selection & Logic:**

* `--trimmer`: `fastp` (default) or `trimmomatic`
* `--aligner`: `bwa-mem2` (default) or `bowtie2`
* `--caller`: `freebayes` (default) or `gatk`
* `--freebayes_mode`: `population` (default) or `individual`
* `--error_estimate`: `false` (default) or `true`
* `--popgen`: Run population genetics module (PCA + phylogenetic tree) from final cohort VCF and add to MultiQC (Default: `true`).
* `--popgen_tree_method`: Tree construction method for population genetics (`upgma`, `nj`, `ml`, or `bayesian`, Default: `upgma`).
* `--popgen_legend_order`: Population legend order for PCA/tree (`samplesheet` or `alphabetical`, Default: `samplesheet`).

**Tool Arguments & Parameters:**

* `--ploidy`: Expected sample ploidy used by variant callers (Default: `2`). Set to `1` for true haploid genomes, or higher values for polyploid organisms.
* `--fastp_args`: Additional arguments passed to Fastp (Default: empty).
* `--trimmomatic_args`: Additional arguments passed to Trimmomatic (Default: `ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36`).
* `--bwa_args`: Additional arguments passed to BWA-mem2 (Default: empty).
* `--bowtie2_args`: Additional arguments passed to Bowtie2 (Default: empty).
* `--gatk_args`: Additional arguments passed to GATK HaplotypeCaller (Default: empty).
* `--freebayes_args`: Additional arguments passed to Freebayes (Default: `--genotype-qualities`). Keep this flag enabled so `GQ` fields are emitted for downstream genotype-based filtering.

**VCF Filtering:**

Note: Genotype-based filtering relies on valid `GQ` fields. By default, HapFun enables Freebayes `--genotype-qualities` (via `--freebayes_args`) so genotype qualities are emitted and filtering behaves as expected.

* `--filter_qual`: Minimum QUAL score (Default: 30)
* `--filter_min_dp`: Minimum Depth (Default: 10)
* `--filter_ind_dp`: Minimum individual genotype depth (Default: 7)
* `--mask_hetero`: Mask heterozygous genotypes (`GT=='het'`) during filtering (Default: `true`). Requires diploid variant calling (`--ploidy 2`).

## Output Directory Structure

Upon completion, the `--outdir` will contain the following structured directories:

```text
    results/
    ├── aligned/              # Final, merged, deduplicated BAM files
    ├── error_estimates/      # CSV reports of replicate discordance rates
    ├── multiqc/              # Aggregated HTML QC report
    ├── population_genetics/  # PCA, phylogenetic tree, and intermediate population-genetics outputs
    ├── qc/                   # Individual QC reports (Fastp, FastQC, Qualimap, BCFtools)
    └── variants/
        ├── error_estimate_libraries/ # Raw per-library VCFs used for error-rate estimation (`--error_estimate true`)
        ├── individual/       # Raw per-sample VCFs (if using individual mode)
        ├── merged/           # Raw aggregated VCF (if using individual mode)
        ├── population/       # Raw aggregated VCF (from Freebayes population mode)
        └── filtered/         # FINAL processed VCFs (SNPs, Indels, and combined)
```

## Credits

HapFun utilizes the following open-source tools via [Bioconda](https://bioconda.github.io/) and [Biocontainers](https://biocontainers.pro/):

* [Fastp](https://github.com/OpenGene/fastp) / [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) / [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic)
* [BWA-mem2](https://github.com/bwa-mem2/bwa-mem2) / [Bowtie2](https://bowtie-mac.sourceforge.net/bowtie2/index.shtml)
* [Samtools](http://www.htslib.org/) / [BCFtools](http://samtools.github.io/bcftools/)
* [GATK4](https://gatk.broadinstitute.org/hc/en-us)
* [Freebayes](https://github.com/freebayes/freebayes)
* [BEDOPS](https://bedops.readthedocs.io/en/latest/) (gff2bed)
* [Qualimap](http://qualimap.conesalab.org/)
* [MultiQC](https://multiqc.info/)

*This pipeline leverages the module patterns and configuration standards developed by the nf-core community.*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
