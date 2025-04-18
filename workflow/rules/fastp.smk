rule clean_fastq:
    input:
        lambda wildcards: SAMPLES[wildcards.sample]["nanopore_input"],
    output:
        r1=OUT + "/clean_unsorted_fastq/{sample}_p.fastq.gz",
        html=OUT + "/clean_fastq/{sample}_fastp.html",
        json=OUT + "/clean_fastq/{sample}_fastp.json",
    message:
        "Filtering low quality reads for {wildcards.sample}."
    conda:
        "../../envs/qc_and_clean.yaml"
    # container:
    #     "docker://biocontainers/fastp:v0.20.1_cv1"
    threads: int(config["threads"]["fastp"])
    resources:
        mem_gb=config["mem_gb"]["fastp"],
    log:
        OUT + "/log/clean_fastq/clean_fastq_{sample}.log",
    params:
        mean_quality=config["mean_quality_threshold"],
        window_size=config["window_size"],
        min_length=config["min_read_length"],
    shell:
        """
        fastp --in1 {input}/*fastq* \
            --out1 {output.r1} \
            --html {output.html} \
            --json {output.json} \
            --report_title "FastP report for sample {wildcards.sample}" \
            --disable_adapter_trimming \
            --disable_quality_filtering \
            --cut_right \
            --cut_mean_quality {params.mean_quality} \
            --cut_window_size {params.window_size} \
            --thread {threads} \
        """