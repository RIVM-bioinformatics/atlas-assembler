rule multiqc:
    input:
       expand(OUT + "/kraken2/flye_assembly/{sample}/{sample}_bracken_species.kreport2", sample=SAMPLES),
       expand(OUT + "/flye_assembly/quast/{sample}/report.tsv", sample=SAMPLES),
       expand(OUT + "/flye_assembly/checkm/per_sample/{sample}/checkm_{sample}.tsv", sample=SAMPLES),
    output:
        OUT + "/multiqc/multiqc.html",
        phred=OUT + "/multiqc/multiqc_data/multiqc_data.json",
        # seq_len=OUT + "/multiqc/multiqc_data/multiqc_fastqc.txt",
    message:
        "Making MultiQC report."
    conda:
        "../../envs/multiqc.yaml"
    threads: config["threads"]["multiqc"]
    resources:
        mem_gb=config["mem_gb"]["multiqc"],
    params:
        config_file="files/multiqc_config.yaml",
        output_dir=OUT + "/multiqc",
    log:
        OUT + "/log/multiqc/multiqc.log",
    shell:
        """
        multiqc --interactive --force --config {params.config_file} \
            -o {params.output_dir} \
            -n multiqc.html {input} &> {log}
        """