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


#Data quality control and cleaning
# include: "workflow/rules/pycoqc.smk"
include: "workflow/rules/nanoplot.smk"
# include: "workflow/rules/filtering.smk"
#include: "workflow/rules/test_sample_sheet.smk"
include: "workflow/rules/fastp.smk"
include: "workflow/rules/assemble_and_polish.smk"

localrules:
    all


rule all:
    input:
        expand(OUT + "/clean_unsorted_fastq/{sample}_p.fastq.gz", sample=SAMPLES),
        expand(OUT + "/nanoplot/fastq_unfiltered/{sample}/", sample=SAMPLES),
        expand(OUT + "/flye/{sample}/assembly/assembly.fasta", sample=SAMPLES),
        # expand(OUT + "/{sample}.fastq.gz", sample=SAMPLES,)
        # fastq_internal = expand(OUT + "/fastq/chopper/unfiltered_{sample}.fastq", sample=SAMPLES), 
        # expand(OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz", sample=SAMPLES),
        # expand(OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percentage"] + ".fastq.gz", sample=SAMPLES),