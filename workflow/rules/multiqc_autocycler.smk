rule multiqc:
    input:
       expand(OUT + "/fastplong/{sample}.json", sample=SAMPLES),
       expand(OUT + "/kraken2/consensus_assembly/{sample}/{sample}_bracken_species.kreport2", sample=SAMPLES),
    #    OUT + "/qc_subset_assembly/quast/report.tsv",
       OUT + "/qc_consensus_assembly/quast/report.tsv",
    #    expand(OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/checkm_{sample}.tsv", sample=SAMPLES),
    #    expand(OUT + "/qc_subset_assembly/busco/{sample}/busco_results_{sample}/short_summary.specific.bacteria_odb10.busco_results_{sample}.txt", sample=SAMPLES),
       expand(OUT + "/qc_consensus_assembly/busco/{sample}/busco_results_{sample}/short_summary.specific.bacteria_odb10.busco_results_{sample}.txt", sample=SAMPLES),
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