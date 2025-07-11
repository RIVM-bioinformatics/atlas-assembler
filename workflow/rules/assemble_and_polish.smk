rule flye:
    input:
        # lambda wildcards: SAMPLES[wildcards.sample]["nanopore_input"]
        # OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percentage"] + ".fastq.gz",
        OUT + "/fastplong/{sample}.fastq",
    output:
        contig = OUT + "/flye/{sample}/assembly/{sample}_assembly.fasta",
    message:
        "Performing assembly with Flye for {wildcards.sample}."
    conda:
        "../../envs/assembly.yaml"
    threads: int(config["threads"]["flye"])
    resources: 
        mem_gb=config["mem_gb"]["flye"],
    params:
        output_dir = OUT + "/flye/{sample}/assembly/"
    log:
        OUT + "/log/flye/{sample}_assembly.log"
    benchmark:
        OUT + "/log/benchmark/flye/{sample}_assembly.txt"
    shell:
        """
echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
outdir="$(dirname "{output.contig}")"
flye --nano-raw {input} \
    --threads {threads} \
    --out-dir {params.output_dir} \
    2> {log} && mv ${{outdir}}/assembly.fasta {output.contig}
        """

rule copy_flye_for_checkm:
    input:
        contig = OUT + "/flye/{sample}/assembly/{sample}_assembly.fasta",
    output:
        copied = OUT + "/flye/{sample}/{sample}_assembly.fasta",
    threads: int(config["threads"]["flye"])
    resources: 
        mem_gb=config["mem_gb"]["flye"],
    shell:
        """
        mkdir -p $(dirname {output.copied})
        cp {input.contig} {output.copied}
        """

# rule medaka_flye:
#     input:
#         assembly = OUT + "/flye/{sample}/assembly/assembly.fasta",
#         longreadset = OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percentage"] + ".fastq.gz"
#     output:
#         # OUT + "/medaka/{sample}/flye/assembly.fasta"
#         # directory(OUT + "/medaka/{sample}/flye"),
#         assembly_out = OUT + "/medaka/{sample}/flye/assembly.fasta"
#     conda:
#         "../../envs/medaka.yaml"
#     threads: int(config["threads"]["medaka"]) # 
#     resources: 
#         # max_mb = config["max_mb"]["medaka"],
#         mem_gb = config["mem_gb"]["medaka"], # 
#         # runtime_min = config["runtime_min"]["medaka"] # 
#     params:
#         outdir = OUT + "/medaka/{sample}/flye",
#         model = config["medaka_model"],
#         rounds = config["medaka_rounds"]
#     log:
#         OUT + "/log/medaka/medaka_flye_{sample}.log"
#     benchmark:
#         OUT + "/log/benchmark/medaka/medaka_flye_{sample}.txt"
#     shell:
#         """
# echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
#     medaka_consensus -i {input.longreadset} \
#         -d {input.assembly} \
#         -o {params.outdir}\
#         -t {threads} \
#         2> {log}
#         """