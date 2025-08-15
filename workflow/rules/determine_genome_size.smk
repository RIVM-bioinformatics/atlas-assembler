import yaml
import os
import glob

rule determine_genome_size:
    input:
        lambda wildcards: SAMPLES[wildcards.sample]["nanopore_input"],
    output:
        OUT + "/genome_size/{sample}/genome_size.txt"
    conda:
        "../../envs/genome_size.yaml"
    threads: config["threads"]["genome_size"] # 8
    resources: 
        mem_gb = config["mem_gb"]["genome_size"], # 48
        run_time_minutes = config["run_time_minutes"]["genome_size"] # 60
    params:
        outdir_sample = OUT + "/genome_size/{sample}"
    log:
        OUT + "/log/genome_size/{sample}/determine_genome_size.log"
    benchmark:
        OUT + "/log/benchmark/genome_size/{sample}/determine_genome_size.txt"
    shell:
        """
       workflow/scripts/genome_size_raven.sh {input}/*fastq* {threads} >> {params.outdir_sample}/genome_size.txt
        """