rule fastplong:
    input:
        lambda wildcards: SAMPLES[wildcards.sample]["nanopore_input"],
    output:
        filtered = OUT + "/fastplong/{sample}.fastq",
        fastplong_json = OUT + "/fastplong/{sample}.json",
        fastplong_html=OUT + "/fastplong/{sample}.html",
    log:
        OUT + "/log/fastplong/{sample}.log",
    conda:
        "../../envs/fastplong.yaml"  # Create this environment if needed
    threads:
        config["threads"]["fastplong"]
    resources:
        mem_gb=config["mem_gb"]["fastplong"],
    shell:
        """
        fastplong -i {input}/*fastq*  -o {output.filtered} -j {output.fastplong_json} -h {output.fastplong_html} > {log} 2>&1
        """