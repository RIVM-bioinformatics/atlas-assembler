rule run_quast:
    input:
        # assembly=lambda wildcards: OUT + f"/medaka/{wildcards.sample}/flye/assembly.fasta"
        assembly = expand(OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta", sample=SAMPLES),
    output:
        report=OUT + "/qc_consensus_assembly/quast/report.tsv",
        quast=OUT + "/qc_consensus_assembly/quast/transposed_report.tsv"
    message:
        "Running QUAST for all samples and creating multireport."
    conda:
        "../../envs/quast.yaml"
    threads:
        config["threads"]["quast"]
    resources:
        mem_gb=config["mem_gb"]["quast"]
    params:
        # output_dir=lambda wildcards: OUT + f"/flye_assembly/quast/{wildcards.sample}"
        output_dir=OUT + "/qc_consensus_assembly/quast",
    log:
        OUT + "/log/qc_consensus_assembly/quast.log"
    shell:
        """
        quast.py --threads {threads} {input.assembly} --output-dir {params.output_dir} > {log}

        """

rule busco:
    input:
        contigs = OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta",
        flag_filtered=lambda wildcards: checkpoints.check_filtered_reads.get(sample=wildcards.sample).output.flag_filtered,
    output:
        # OUT + directory("/busco/{sample}/")
        busco_out = directory(OUT + "/qc_consensus_assembly/busco/{sample}/"),
        short_summary = OUT + "/qc_consensus_assembly/busco/{sample}/busco_results_{sample}/short_summary.specific.bacteria_odb10.busco_results_{sample}.txt"
    message:
        "Running BUSCO for {wildcards.sample}"
    conda:
        "../../envs/busco.yaml"
    log:
        OUT + "/log/qc_consensus_assembly/busco/{sample}/busco.out"
    params:
        mode = "genome",
        lineage = "bacteria_odb10",
        short_summary_filename = "busco_results_{sample}",
        # options = config['busco']['options']
    threads:
        config["threads"]["busco"]
    resources:
        mem_gb=config["mem_gb"]["busco"]
    shell:
        """
        if [ $(< {input.flag_filtered}) == "sufficient" ]; then
            busco -i {input.contigs} --out_path {output.busco_out} -l {params.lineage} -o {params.short_summary_filename}\
            -m {params.mode} -f
        else
            echo "Not enough coverage to run BUSCO" > {output.short_summary}
        fi
        """
