rule run_quast:
    input:
        # assembly=lambda wildcards: OUT + f"/medaka/{wildcards.sample}/flye/assembly.fasta"
        assembly = OUT + "/flye/{sample}/assembly/assembly.fasta"
    output:
        report=OUT + "/flye_assembly/quast/{sample}/report.tsv",
        quast=OUT + "/flye_assembly/quast/{sample}/transposed_report.tsv"
    message:
        "Running QUAST for {wildcards.sample} and creating multireport."
    conda:
        "../../envs/quast.yaml"
    threads:
        config["threads"]["quast"]
    resources:
        mem_gb=config["mem_gb"]["quast"]
    params:
        output_dir=lambda wildcards: OUT + f"/flye_assembly/quast/{wildcards.sample}"
    log:
        OUT + "/log/flye_assembly/quast_{sample}.log"
    shell:
        """
        quast.py --threads {threads} {input.assembly} --output-dir {params.output_dir} > {log}
        """