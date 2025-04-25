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
include: "workflow/rules/kraken2.smk"
include: "workflow/rules/assemble_and_polish.smk"
include: "workflow/rules/post_qc.smk"
include: "workflow/rules/multiqc.smk"

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
        expand(OUT + "/kraken2/flye/{sample}/{sample}_read-report.txt", sample=SAMPLES),
        expand(OUT + "/kraken2/flye/{sample}/{sample}_assembly-report.txt", sample=SAMPLES),
        expand(OUT + "/flye/{sample}/assembly/assembly.fasta", sample=SAMPLES),
        # expand(OUT + "/medaka/{sample}/flye/assembly.fasta", sample=SAMPLES),
        # expand(OUT + "/medaka/{sample}/flye", sample=SAMPLES),
        expand(OUT + "/flye_assembly/quast/{sample}/report.tsv", sample=SAMPLES),
        expand(OUT + "/flye_assembly/quast/{sample}/transposed_report.tsv", sample=SAMPLES),
        expand(OUT + "/multiqc/multiqc.html", sample=SAMPLES),
        expand(OUT + "/multiqc/multiqc_data/multiqc_data.json", sample=SAMPLES),
   