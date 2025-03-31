rule filtlong:
    input:
        gz_chopper = OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz"
    output: # If I want to add option to not filter at all (because it has already been done for example) I could make the keep_percent_str to be '_best90' for example. And then if statement for keep_percent flag yes or no.
        temp(OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percent_str"] + ".fastq.gz")
    conda:
        "envs/amr_longread.yaml"
    # singularity:
    #     singularity run https://depot.galaxyproject.org/singularity/filtlong:0.2.1--hd03093a_1
    threads: config["threads"]["default"]
    resources: 
        max_mb = config["max_mb"]["default"],
        mem_mb = config["mem_mb"]["default"],
        runtime_min = config["runtime_min"]["default"]
    params:
        filtlong_temp = OUT + "/tmp/temp{sample}.fastq",
        keep_percent = config["keep_percent"],
    log:
        OUT + "/log/filtlong/{sample}.log"
    benchmark:
        OUT + "/log/benchmark/filtlong/{sample}.txt"
    shell: # Write to a temp file because otherwise Snakemake seemed to think the final file had already been created and tried to continue.
        """
echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
zcat -f {input.gz_chopper} > {params.filtlong_temp} \
&& \
filtlong    --min_length 1000 \
            --keep_percent {params.keep_percent} \
            {params.filtlong_temp} | gzip > {output} \
            2> {log} \
&& \
rm {params.filtlong_temp}*
        """
# cp {params.filtlong_temp}.gz {output} && \

rule chopper:
    input:
        lambda wildcards: config["samples"][wildcards.sample]["nanopore_input"]
    output: # The unfiltered set to get QC on data directly from the nanopore sequencer, the gz_chopper to clip 80 bp from head and tail for easy removal of barcodes and filter for a min length.
        fastq_internal = temp(OUT + "/fastq/chopper/unfiltered_{sample}.fastq"), 
        gz_chopper = temp(OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz")
    conda:
        "envs/nanoplot.yaml"
    threads: config["threads"]["default"]
    resources: 
        mem_mb = config["mem_mb"]["default"],
        max_mb = config["max_mb"]["default"],
        runtime_min = config["runtime_min"]["default"]
    params:
        irods_mode = lambda wildcards: config["samples"][wildcards.sample]["iRODS_mode"], #The iRODS mode is actually true for the entire run so doesn't have to be sample specific, but it's not wrong.
        length = config["length"],
        headcrop = config["headcrop"],
        tailcrop = config["tailcrop"]
    log:
        OUT + "/log/chopper/{sample}.log"
    benchmark:
        OUT + "/log/benchmark/chopper_{sample}.txt"
    shell: # Data from iRODS is always inside a directory per isolate so it's zcat {input}/*fastq* in non irods_mode input is a single file per isolate.
        """
echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
if [ {params.irods_mode} == "True" ]
then
zcat -f {input}/*fastq* | chopper \
    > {output.fastq_internal}
zcat -f {input}/*fastq* | chopper \
    --quality 12 \
    --minlength {params.length} \
    --headcrop {params.headcrop} \
    --tailcrop {params.tailcrop} \
    | pigz > {output.gz_chopper}
else
zcat -f {input} | chopper \
    > {output.fastq_internal}
zcat -f {input} | chopper \
    --minlength {params.length} \
    --quality 12 \
    --headcrop {params.headcrop} \
    --tailcrop {params.tailcrop} \
    | pigz > {output.gz_chopper}
fi
        """