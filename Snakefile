import yaml


sample_sheet=config["sample_sheet"]
SAMPLES = {}
with open(sample_sheet) as f:
    SAMPLES = yaml.safe_load(f)

for param in ["threads", "mem_gb", "run_time_minutes"]:
    for k in config[param]:
        config[param][k] = int(config[param][k])

print(SAMPLES)

OUT = config["output_dir"]
IN = config["input_dir"]

# AUTOCYCLER_EXE = config["autocycler_executable"] #where does this come from?
subsets_used = ["01", "02", "03", "04"]
# assembler_list = ["canu", "flye", "miniasm", "necat", "nextdenovo", "raven"]
assembler_list = ["flye","miniasm", "raven", "nextdenovo"]


def determine_threads(wildcards, attempt, base_threads):
    return attempt * base_threads 

def determine_runtime(wildcards, attempt, base_time):
    return attempt * base_time 

def determine_memory(wildcards, attempt, base_mem): # Same multiplying as with time now but might change it so separate function
    return attempt * base_mem 

def determine_final_try(wildcards, attempt):
    return attempt * 1


include: "workflow/rules/fastplong.smk"
include: "workflow/rules/nanoplot.smk"
include: "workflow/rules/identify_species_autocycler.smk"
include: "workflow/rules/create_atlas_species_summary.smk"
include: "workflow/rules/autocycler.smk"
include: "workflow/rules/checkm_autocycler.smk"
include: "workflow/rules/parse_checkm_autocycler.smk"
include: "workflow/rules/post_qc_autocycler.smk"
include: "workflow/rules/multiqc_autocycler.smk"
include: "workflow/rules/create_atlas_qc_report.smk"



localrules:
    all

rule all:
    input:
        # expand(OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz", sample=SAMPLES),
        expand(OUT + "/fastplong/{sample}.fastq", sample=SAMPLES),
        expand(OUT + "/fastplong/fastplong_summary.tsv"),
        expand(OUT + "/nanoplot/{sample}/", sample=SAMPLES),
        expand(OUT + "/nanoplot/{sample}/NanoStats.txt", sample=SAMPLES),
        expand(OUT + "/nanoplot/NanoStats_summary.tsv"),
        expand(OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta", sample=SAMPLES),
        expand(OUT + "/identify_species/reads/{sample}/{sample}_species_content.txt", sample=SAMPLES),
        expand(OUT + "/identify_species/reads/{sample}/{sample}_bracken_species.kreport2", sample=SAMPLES),
        expand(OUT + "/identify_species/consensus_assembly/{sample}/{sample}_species_content.txt", sample=SAMPLES),
        expand(OUT + "/identify_species/consensus_assembly/{sample}/{sample}_bracken_species.kreport2", sample=SAMPLES),
        OUT + "/identify_species/skani_results.tsv",
        OUT + "/identify_species/top1_species_multireport.csv",
        expand(OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/checkm_{sample}.tsv", sample=SAMPLES),
        expand(OUT + "/qc_consensus_assembly/quast/report.tsv", sample=SAMPLES),
        expand(OUT + "/qc_consensus_assembly/busco/{sample}/", sample=SAMPLES),
        expand(OUT + "/qc_consensus_assembly/busco/{sample}/busco_results_{sample}/short_summary.specific.bacteria_odb10.busco_results_{sample}.txt", sample=SAMPLES),
        expand(OUT + "/multiqc/multiqc.html", sample=SAMPLES),
        expand(OUT + "/multiqc/multiqc_data/multiqc_data.json", sample=SAMPLES),
        OUT + "/Atlas_assembly_QC_report/QC_report.xlsx",
        