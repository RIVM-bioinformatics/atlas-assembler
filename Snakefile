import yaml


sample_sheet=config["sample_sheet"]
with open(sample_sheet) as f:
    SAMPLES = yaml.safe_load(f)

for param in ["threads", "mem_gb"]:
    for k in config[param]:
        config[param][k] = int(config[param][k])

# print(SAMPLES)

OUT = config["output_dir"]


#Data quality control and cleaning
# include: "workflow/rules/pycoqc.smk"
# include: "workflow/rules/nanoplot.smk"
# include: "workflow/rules/filtering.smk"
include: "workflow/rules/test_sample_sheet.smk"

localrules:
    all,


rule all:
    input:
        expand(OUT + "/{sample}_combined.fastq", sample=SAMPLES),
