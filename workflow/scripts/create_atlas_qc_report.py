import sys
# Redirect all printing and exceptions to the snakemake log of this rule
sys.stdout = sys.stderr = open(snakemake.log[0], "w")  # type: ignore

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

def get_quast(quast_csv: str) -> pd.DataFrame:
    quast_df = pd.read_csv(quast_csv, sep='\t', usecols=["Assembly", "Total length", "# contigs", "N50", "GC (%)"])
    quast_df.rename(
    columns={"Assembly": "sample", "Total length": "Total length (Mbp)"},
    inplace=True,
)
    quast_df["sample"] = quast_df["sample"].astype(str)
    if any(quast_df['sample'].str.contains("_")):
        quast_df['sample'] = quast_df['sample'].apply(lambda x: x.rsplit('_', 1)[0])

    return quast_df

def get_checkm(checkm_csv: str) -> pd.DataFrame:
    checkm_df = pd.read_csv(checkm_csv, sep='\t', usecols=["sample", "completeness", "contamination"])
    checkm_df["sample"] = checkm_df["sample"].astype(str)
    checkm_df["sample"] = checkm_df["sample"].str[:-1]
    checkm_df.rename(
        columns={
            "completeness": "completeness (%)",
            "contamination": "contamination (%)",
        },
        inplace=True,
    )
    # if any(checkm['sample'].str.contains("_")):
    #     checkm['sample'] = checkm['sample'].apply(lambda x: x.split('_')[0])
    checkm_df['sample'] = checkm_df['sample'].astype(str).str.replace('-', '_')

    return checkm_df

def compile_report(
    species_csv: str,
    phred_csv: str,
    fastp_csv: str,
    quast_csv: str,
    checkm_csv: str
) -> pd.DataFrame:
    species_df = get_genus(species_csv)
    phred_df = get_phred(phred_csv)
    fastp_df = get_fastp(fastp_csv)
    quast_df = get_quast(quast_csv)
    checkm_df = get_checkm(checkm_csv)

    dfs = [species_df, phred_df, fastp_df, quast_df, checkm_df]
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
)
write_excel_report(report_df, snakemake.output[0])  # type: ignore
