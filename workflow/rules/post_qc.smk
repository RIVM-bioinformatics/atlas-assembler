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

rule busco:
    input:
        contigs = OUT + "/flye/{sample}/assembly/assembly.fasta"
    output:
        # OUT + directory("/busco/{sample}/")
        busco_out = directory(OUT + "/busco/{sample}/"),
        short_summary = OUT + "/busco/{sample}/busco_results/short_summary.specific.bacteria_odb10.busco_results.txt"
    message:
        "Running BUSCO for {wildcards.sample}"
    conda:
        "../../envs/busco.yaml"
    log:
        OUT + "/log/busco/{sample}/busco.out"
    params:
        mode = "genome",
        lineage = "bacteria_odb10",
        short_summary_filename = "busco_results",
        # options = config['busco']['options']
    threads:
        config["threads"]["busco"]
    resources:
        mem_gb=config["mem_gb"]["busco"]
    shell:
        """
        busco -i {input.contigs} --out_path {output.busco_out} -l {params.lineage} -o {params.short_summary_filename}\
        -m {params.mode} -f 
        """