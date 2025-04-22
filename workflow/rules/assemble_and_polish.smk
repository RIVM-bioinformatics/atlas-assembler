rule flye:
    input:
        OUT + "/clean_unsorted_fastq/{sample}_p.fastq.gz"
        # OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percent_str"] + ".fastq.gz"
    output:
        OUT + "/flye/{sample}/assembly/assembly.fasta",
    message:
        "Performing assembly with Flye for {wildcards.sample}."
    conda:
        "../../envs/assembly.yaml"
    threads: int(config["threads"]["flye"])
    resources: 
        mem_gb=config["mem_gb"]["flye"],
    params:
        outdir = OUT + "/flye/{sample}/assembly/"
    log:
        OUT + "/log/flye/{sample}_assembly.log"
    benchmark:
        OUT + "/log/benchmark/flye/{sample}_assembly.txt"
    shell:
        """
echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
flye --nano-raw {input} \
    --threads {threads} \
    --out-dir {params.outdir} \
    2> {log}
        """