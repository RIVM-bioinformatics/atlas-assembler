import sys
# Redirect all printing and exceptions to the snakemake log of this rule
sys.stdout = sys.stderr = open(snakemake.log[0], "w")  # type: ignore
import os
import pandas as pd
from functools import reduce
import json
import openpyxl

def get_genus(species_csv: str) -> pd.DataFrame:
    species_df = pd.read_csv(species_csv, usecols=['sample', 'genus', 'species'])
    species_df['sample'] = species_df['sample'].astype(str).str.replace('-', '_')
    return species_df

def get_phred(phred_csv: str) -> pd.DataFrame:
    phred_df = pd.read_csv(phred_csv, sep='\t', usecols=['sample', 'Mean read quality'])
    phred_df['sample'] = phred_df['sample'].astype(str).str.replace('-', '_')
    return phred_df

def get_fastp(fastp_csv: str) -> pd.DataFrame:
    fastp_df = pd.read_csv(fastp_csv, sep='\t', usecols=['sample', 'after_read_mean_length', 'after_total_reads'])
    fastp_df.rename(columns={'sample': 'sample', 'after_read_mean_length': 'avg_sequence_length', 'after_total_reads': 'Reads'}, inplace=True)
    fastp_df['sample'] = fastp_df['sample'].astype(str).str.replace('-', '_')
    return fastp_df

# def get_quast(quast_csv: str) -> pd.DataFrame:
#     quast_df = pd.read_csv(quast_csv, sep='\t', usecols=["Assembly", "Total length", "# contigs", "GC (%)", "N50", "L50", "N90", "L90"])
#     quast_df.rename(
#     columns={"Assembly": "sample", "Total length": "Total length (Mbp)"},
#     inplace=True,
# )
#     quast_df["sample"] = quast_df["sample"].astype(str)
#     if any(quast_df['sample'].str.contains("_")):
#         quast_df['sample'] = quast_df['sample'].apply(lambda x: x.rsplit('_', 1)[0])

#     return quast_df

def get_quast(quast_csv: str) -> pd.DataFrame:
    quast_df = pd.read_csv(quast_csv, sep='\t', usecols=["Assembly", "Total length", "# contigs", "GC (%)", "N50", "L50", "N90", "L90"])
    quast_df.rename(
        columns={"Assembly": "sample", "Total length": "Total length (Mbp)"},
        inplace=True,
    )
    quast_df["sample"] = (
        quast_df["sample"]
        .astype(str)
        .str.replace("-", "_", regex=False)
        .str.replace("_autocycler$", "", regex=True)
    )
    return quast_df

def get_checkm(checkm_csv: str) -> pd.DataFrame:
    checkm_df = pd.read_csv(checkm_csv, sep='\t',
                            index_col=False,
                            usecols=["sample", "completeness", "contamination"], 
                            dtype={"sample": str, "completeness": float, "contamination": float})
    checkm_df["sample"] = checkm_df["sample"].astype(str).str.rstrip('L')  # Remove trailing underscore if present
    checkm_df.rename(
        columns={
            "completeness": "completeness (%)",
            "contamination": "contamination (%)",
        },
        inplace=True,
    )
    checkm_df['sample'] = checkm_df['sample'].astype(str).str.replace('-', '_', regex=False)
    return checkm_df



# def get_coverage(genome_size_txt_list, fastplong_csv):
#     # Read fastplong summary
#     fastplong_df = pd.read_csv(fastplong_csv, sep='\t')
#     fastplong_df['sample'] = fastplong_df['sample'].astype(str).str.replace('-', '_')

#     # Build a sample:genome_size dictionary
#     genome_sizes = {}
#     for path in genome_size_txt_list:
#         # sample = os.path.basename(path).replace('_genome_size.txt', '').replace('-', '_')
#         # sample = os.path.basename(path)
#         sample = os.path.basename(os.path.dirname(path)).replace('-', '_')
#         with open(path) as f:
#             if genome_sizes.get(sample) == "Unable to determine genome size":
#                 genome_sizes[sample] = 0
#             else:
#                 genome_sizes[sample] = float(f.read().strip())
#     # sample = os.path.basename(path).replace('_genome_size.txt', '').replace('-', '_')
#     # Map genome size to each sample
#     fastplong_df['genome_size'] = fastplong_df['sample'].map(genome_sizes)
#     fastplong_df['coverage'] = fastplong_df['after_total_bases'] / fastplong_df['genome_size']

#     coverage_df = fastplong_df[['sample', 'coverage']]

#     return coverage_df

def get_coverage(genome_size_txt_list, fastplong_csv):
    # Read fastplong summary
    fastplong_df = pd.read_csv(fastplong_csv, sep='\t')
    fastplong_df['sample'] = fastplong_df['sample'].astype(str).str.replace('-', '_')

    # Build a sample:genome_size dictionary
    genome_sizes = {}
    for path in genome_size_txt_list:
        sample = os.path.basename(os.path.dirname(path)).replace('-', '_')
        with open(path) as f:
            content = f.read().strip()
            if content == "Unable to determine genome size":
                genome_sizes[sample] = None
            else:
                try:
                    genome_sizes[sample] = float(content)
                except Exception:
                    genome_sizes[sample] = None

    # Map genome size to each sample
    fastplong_df['genome_size'] = fastplong_df['sample'].map(genome_sizes)

    # Calculate coverage, handling missing genome size
    def coverage_or_message(row):
        if row['genome_size'] is None or row['genome_size'] == 0:
            return "Unable to calculate coverage "
        else:
            return row['after_total_bases'] / row['genome_size']

    fastplong_df['coverage'] = fastplong_df.apply(coverage_or_message, axis=1)

    coverage_df = fastplong_df[['sample', 'coverage']]

    return coverage_df

def compile_report(
    species_csv: str,
    phred_csv: str,
    fastp_csv: str,
    quast_csv: str,
    checkm_csv: str,
    genome_size_txt: str,
) -> pd.DataFrame:
    species_df = get_genus(species_csv)
    phred_df = get_phred(phred_csv)
    fastp_df = get_fastp(fastp_csv)
    quast_df = get_quast(quast_csv)
    coverage_df = get_coverage(genome_size_txt, fastp_csv)
    checkm_df = get_checkm(checkm_csv)

    dfs = [species_df, phred_df, fastp_df, quast_df, coverage_df, checkm_df]
    final_df = reduce(lambda left, right: pd.merge(left, right, on='sample', how='outer'), dfs)
    final_df["Total length (Mbp)"] = final_df["Total length (Mbp)"] / 1_000_000
    return final_df

def write_excel_report(df: pd.DataFrame, outfile: str) -> None:
    """
    Creates an excel format report with conditional formatting
    """
    with pd.ExcelWriter(outfile, engine="openpyxl") as writer:
        for genus, species_df in df.groupby("genus"):
            species_df["genus"] = str(genus)
            species_df.to_excel(writer, sheet_name=str(genus), index=False)


report_df = compile_report(
    snakemake.input.species,  # type: ignore
    snakemake.input.phred,  # type: ignore
    snakemake.input.fastp,  # type: ignore
    snakemake.input.quast,  # type: ignore
    snakemake.input.checkm,  # type: ignore
    snakemake.input.genome_size,  # type: ignore
)
write_excel_report(report_df, snakemake.output[0])  # type: ignore