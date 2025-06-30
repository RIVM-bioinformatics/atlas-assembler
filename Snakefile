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
assembler_list = ["canu", "flye", "miniasm", "necat", "nextdenovo", "raven"]


# include: "workflow/rules/nanoplot.smk"
include: "workflow/rules/filtering.smk"
# include: "workflow/rules/fastp.smk"
# include: "workflow/rules/kraken2.smk"
# include: "workflow/rules/identify_species.smk"
# include: "workflow/rules/assemble_and_polish.smk"
# include: "workflow/rules/post_qc.smk"
# include: "workflow/rules/run_checkm.smk"
# include: "workflow/rules/parse_checkm.smk"
# include: "workflow/rules/multiqc.smk"
include: "workflow/rules/identify_species_autocycler.smk"
include: "workflow/rules/autocycler.smk"
include: "workflow/rules/post_qc_autocycler.smk"
include: "workflow/rules/multiqc_autocycler.smk"



localrules:
    all

rule all:
    input:
        expand(OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz", sample=SAMPLES),
        expand(OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta", sample=SAMPLES),
        expand(OUT + "/kraken2/reads/{sample}/{sample}_species_content.txt", sample=SAMPLES),
        expand(OUT + "/kraken2/reads/{sample}/{sample}_bracken_species.kreport2", sample=SAMPLES),
        expand(OUT + "/kraken2/consensus_assembly/{sample}/{sample}_species_content.txt", sample=SAMPLES),
        expand(OUT + "/kraken2/consensus_assembly/{sample}/{sample}_bracken_species.kreport2", sample=SAMPLES),
        OUT + "/kraken2/consensus_assembly/top1_species_multireport.csv",
        expand(OUT + "/qc_consensus_assembly/quast/report.tsv", sample=SAMPLES),
        expand(OUT + "/qc_consensus_assembly/busco/{sample}/", sample=SAMPLES),
        expand(OUT + "/qc_consensus_assembly/busco/{sample}/busco_results_{sample}/short_summary.specific.bacteria_odb10.busco_results_{sample}.txt", sample=SAMPLES),
        expand(OUT + "/multiqc/multiqc.html", sample=SAMPLES),
        expand(OUT + "/multiqc/multiqc_data/multiqc_data.json", sample=SAMPLES),