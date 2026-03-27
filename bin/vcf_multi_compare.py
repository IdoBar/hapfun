#!/usr/bin/env python3
import pysam
import argparse
import pandas as pd
import itertools
import os

def get_variants_dict(vcf_path, chrom):
    """Extracts genotypes for a given chromosome into a dictionary."""
    vcf = pysam.VariantFile(vcf_path)
    variants = {}
    sample_name = vcf.header.samples[0]
    
    try:
        for rec in vcf.fetch(chrom):
            if sample_name not in rec.samples:
                continue
            gt = rec.samples[sample_name]['GT']
            # Skip missing calls
            if gt is None or None in gt:
                continue
            # Sort the genotype tuple to ensure (0,1) matches (1,0) if diploid, 
            # and works perfectly for haploid (1,)
            variants[rec.pos] = sorted(gt)
    except ValueError:
        # Happens if the chromosome is not present in the VCF
        return {}
        
    return variants

def compare_files(vcf_list, sample_id, output_file):
    """Compares all pairwise combinations of VCFs for a sample."""
    first_vcf = pysam.VariantFile(vcf_list[0])
    chromosomes = list(first_vcf.header.contigs)
    results = []
    
    # Generate all unique pairs of libraries to compare
    pairs = list(itertools.combinations(vcf_list, 2))
    
    print(f"Sample {sample_id}: Comparing {len(vcf_list)} libraries ({len(pairs)} pairwise comparisons)...")

    for vcf_a_path, vcf_b_path in pairs:
        name_a = os.path.basename(vcf_a_path).replace('.vcf.gz', '')
        name_b = os.path.basename(vcf_b_path).replace('.vcf.gz', '')
        
        stats = {
            'sample': sample_id, 
            'file_a': name_a, 
            'file_b': name_b, 
            'shared_sites': 0, 
            'concordant': 0, 
            'discordant': 0
        }

        for chrom in chromosomes:
            vars_a = get_variants_dict(vcf_a_path, chrom)
            vars_b = get_variants_dict(vcf_b_path, chrom)
            
            # Only compare sites where both libraries have a valid call
            common_pos = set(vars_a.keys()).intersection(vars_b.keys())
            stats['shared_sites'] += len(common_pos)
            
            for pos in common_pos:
                if vars_a[pos] == vars_b[pos]:
                    stats['concordant'] += 1
                else:
                    stats['discordant'] += 1

        if stats['shared_sites'] > 0:
            stats['discordance_rate'] = (stats['discordant'] / stats['shared_sites']) * 100
        else:
            stats['discordance_rate'] = 0.0
            
        results.append(stats)

    # Export to CSV
    df = pd.DataFrame(results)
    df.to_csv(output_file, index=False)
    print(f"Saved discordance report to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate pairwise VCF discordance.")
    parser.add_argument("--vcfs", nargs='+', required=True, help="List of VCF files to compare")
    parser.add_argument("--sample", required=True, help="Sample ID")
    parser.add_argument("--out", required=True, help="Output CSV filename")
    args = parser.parse_args()
    
    # Failsafe: if fewer than 2 VCFs are passed, output an empty formatted CSV
    if len(args.vcfs) < 2:
        with open(args.out, 'w') as f:
            f.write("sample,file_a,file_b,shared_sites,concordant,discordant,discordance_rate\n")
    else:
        compare_files(args.vcfs, args.sample, args.out)