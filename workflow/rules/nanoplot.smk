rule nanoplot:
    input:
        fastp = OUT + "/clean_unsorted_fastq/{sample}_p.fastq.gz",
        # fastq_internal = OUT + "/fastq/chopper/unfiltered_{sample}.fastq",
        # gz_chopper = OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz",
        # gz_filtlong = OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percent_str"] + ".fastq.gz"
    output:
        nano_fastp = directory(OUT + "/nanoplot/fastq_unfiltered/{sample}/"),
        # fastq_internal = OUT + "/nanoplot/fastq_unfiltered/{sample}/{sample}_NanoStats.csv",
        # gz_chopper = OUT + "/nanoplot/gz_chopper/{sample}/{sample}_NanoStats.csv",
        # gz_filtlong = OUT + "/nanoplot/gz_filtlong/{sample}/{sample}_NanoStats.csv",
        # read_depth_try = OUT + "/nanoplot/gz_filtlong/{sample}/min_read_depth.txt" # Was needed for Trycycler subsets but it does make the rule all clean, its a file created by the Python script in this rule.
    conda:
        "../../envs/nanoplot.yaml"
    threads: int(config["threads"]["fastp"])
    resources: 
        mem_gb=config["mem_gb"]["fastp"]
    log:
        OUT + "/log/nanoplot/{sample}.log"
    benchmark:
        OUT + "/log/nanoplot/nanoplot_{sample}.txt"
    shell: # Only when all 3 NanoPlot reports have been generated can the edit python script start - So yeah they run sequentially now
        """
echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
NanoPlot --fastq {input.fastp} --outdir {output.nano_fastp} 
        """