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
        if [ -d {input} ]; then \
           fastplong -i {input}/*fastq*  -o {output.filtered} -j {output.fastplong_json} -h {output.fastplong_html}  > {log} 2>&1
        else \
           fastplong -i {input} -o {output.filtered} -j {output.fastplong_json} -h {output.fastplong_html}  > {log} 2>&1
        fi
        """
    
    
rule fastplongjson_to_tsv:
    input:
        expand(OUT + "/fastplong/{sample}.json", sample=SAMPLES),
    output:
        tsv= OUT + "/fastplong/fastplong_summary.tsv",
    threads: int(config["threads"]["fastplong"]),
    resources: 
        mem_gb=config["mem_gb"]["fastplong"],
    shell:
        """
        python workflow/scripts/parse_fastplong.py {input} {output.tsv}
        """