rule nanoplot:
    input:
        fastq_internal = OUT + "/fastq/chopper/unfiltered_{sample}.fastq",
        gz_chopper = OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz",
        gz_filtlong = OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percent_str"] + ".fastq.gz"
    output:
        # fastq_internal = OUT + "/nanoplot/fastq_unfiltered/{sample}/{sample}_NanoStats.csv",
        # gz_chopper = OUT + "/nanoplot/gz_chopper/{sample}/{sample}_NanoStats.csv",
        # gz_filtlong = OUT + "/nanoplot/gz_filtlong/{sample}/{sample}_NanoStats.csv",
        read_depth_try = OUT + "/nanoplot/gz_filtlong/{sample}/min_read_depth.txt" # Was needed for Trycycler subsets but it does make the rule all clean, its a file created by the Python script in this rule.
    conda:
        "envs/nanoplot.yaml"
    threads: config["threads"]["default"]
    resources: 
        max_mb = config["max_mb"]["default"],
        mem_mb = config["mem_mb"]["default"],
        runtime_min = config["runtime_min"]["default"]
    params:
        out_fastq_internal = OUT + "/nanoplot/fastq_unfiltered/{sample}",
        out_gz_chopper = OUT + "/nanoplot/gz_chopper/{sample}",
        out_gz_filtlong = OUT + "/nanoplot/gz_filtlong/{sample}",
        workdir = config["workdir"],
        snakedir = config["snakemake_directory"]
    log:
        OUT + "/log/nanoplot/{sample}.log"
    benchmark:
        OUT + "/log/nanoplot/nanoplot_{sample}.txt"
    shell: # Only when all 3 NanoPlot reports have been generated can the edit python script start - So yeah they run sequentially now
        """
echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
NanoPlot --fastq {input.fastq_internal} \
        -o {params.out_fastq_internal} \
        2> {log} \
&& \
NanoPlot --fastq {input.gz_chopper} \
        -o {params.out_gz_chopper} \
        2> {log} \
&& \
NanoPlot --fastq {input.gz_filtlong} \
        -o {params.out_gz_filtlong} \
        2> {log} \
&& \
python bin/edit_nanoplot_longread.py --sample {wildcards.sample} --workdir {params.workdir} --snakedir {params.snakedir}
        """