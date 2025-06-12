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


include: "workflow/rules/nanoplot.smk"
include: "workflow/rules/filtering.smk"
# include: "workflow/rules/fastp.smk"
# include: "workflow/rules/kraken2.smk"
include: "workflow/rules/identify_species.smk"
include: "workflow/rules/assemble_and_polish.smk"
include: "workflow/rules/post_qc.smk"
include: "workflow/rules/run_checkm.smk"
include: "workflow/rules/parse_checkm.smk"
include: "workflow/rules/multiqc.smk"
# include: "rules/autocycler.smk"



localrules:
    all


rule all:
    input:
        # expand(OUT + "/clean_unsorted_fastq/{sample}_p.fastq.gz", sample=SAMPLES),
        # expand(OUT + "/{sample}.fastq.gz", sample=SAMPLES,)
        # fastq_internal = expand(OUT + "/fastq/chopper/unfiltered_{sample}.fastq", sample=SAMPLES), 
        expand(OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz", sample=SAMPLES),
        expand(OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percentage"] + ".fastq.gz", sample=SAMPLES),
        expand(OUT + "/nanoplot/{sample}/", sample=SAMPLES),
        expand(OUT + "/nanoplot/{sample}/NanoStats.txt", sample=SAMPLES),
        expand(OUT + "/kraken2/reads/{sample}/{sample}_species_content.txt", sample=SAMPLES),
        expand(OUT + "/kraken2/reads/{sample}/{sample}_bracken_species.kreport2", sample=SAMPLES),
        # expand(OUT + "/kraken2/flye/{sample}/{sample}_read-report.txt", sample=SAMPLES),
        # expand(OUT + "/kraken2/flye/{sample}/{sample}_assembly-report.txt", sample=SAMPLES),
        # expand(OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta", sample=SAMPLES),
        expand(OUT + "/flye/{sample}/assembly/{sample}_assembly.fasta", sample=SAMPLES),
        # expand(OUT + "/medaka/{sample}/flye/assembly.fasta", sample=SAMPLES),
        # expand(OUT + "/medaka/{sample}/flye", sample=SAMPLES),
        expand(OUT + "/qc_flye_assembly/checkm/per_sample/{sample}/checkm_{sample}.tsv", sample=SAMPLES),
        expand(OUT + "/qc_flye_assembly/quast/report.tsv", sample=SAMPLES),
        # expand(OUT + "/flye_assembly/quast/{sample}/transposed_report.tsv", sample=SAMPLES),
        expand(OUT + "/qc_flye_assembly/busco/{sample}/", sample=SAMPLES),
        expand(OUT + "/qc_flye_assembly/busco/{sample}/busco_results_{sample}/short_summary.specific.bacteria_odb10.busco_results_{sample}.txt", sample=SAMPLES),
        OUT + "/identify_species/top1_species_multireport.csv",
        expand(OUT + "/multiqc/multiqc.html", sample=SAMPLES),
        expand(OUT + "/multiqc/multiqc_data/multiqc_data.json", sample=SAMPLES),
   