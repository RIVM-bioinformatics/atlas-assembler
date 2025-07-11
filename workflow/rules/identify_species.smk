rule identify_species_reads:
    input:
        # gz_filtlong = OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percentage"] + ".fastq.gz",
        filtered = OUT + "/fastplong/{sample}.fastq",
    output:
        # read_report = OUT + "/kraken2/flye/{sample}/{sample}_read-report.txt",
        kraken2_kreport = OUT + "/kraken2/reads/{sample}/{sample}.kreport2",
        bracken_s = OUT + "/kraken2/reads/{sample}/{sample}_species_content.txt",
        bracken_kreport=OUT + "/kraken2/reads/{sample}/{sample}_bracken_species.kreport2",
    conda:
        "../../envs/identify_species.yaml"
    threads: int(config["threads"]["kraken2"])
    resources:
        mem_gb = config["mem_gb"]["kraken2"],
        # runtime_min = config["runtime_min"]["kraken2"]
    params:
        out_sample = OUT + "/kraken2/reads/{sample}/{sample}",
        kraken2_db = config["db_dir"],
    log:
        OUT + "/log/kraken2/{sample}-flye.log"
    benchmark:
        OUT + "/log/kraken2/kraken2_{sample}-flye.txt"
    shell: 
        """
        kraken2 \
        --threads 4 \
        --db {params.kraken2_db} \
        --classified-out {params.out_sample}_classified_reads.txt \
        --unclassified-out {params.out_sample}_unclassified_reads.txt \
        --report {output.kraken2_kreport} \
        --output - \
        {input.filtered}

        bracken -d {params.kraken2_db} \
        -i {output.kraken2_kreport} \
        -o {output.bracken_s} \
        -r 150 \
        -l S \
        -t 0  &>> {log} 
        """

rule identify_species:
    input:
        assembly = OUT + "/flye/{sample}/assembly/{sample}_assembly.fasta", # Can be the unedited raw fasta file
    output:
        # read_report = OUT + "/kraken2/flye/{sample}/{sample}_read-report.txt",
        kraken2_kreport = OUT + "/kraken2/flye_assembly/{sample}/{sample}.kreport2",
        bracken_s = OUT + "/kraken2/flye_assembly/{sample}/{sample}_species_content.txt",
        bracken_kreport=OUT + "/kraken2/flye_assembly/{sample}/{sample}_bracken_species.kreport2",
    conda:
        "../../envs/identify_species.yaml"
    threads: int(config["threads"]["kraken2"])
    resources:
        mem_gb = config["mem_gb"]["kraken2"],
        # runtime_min = config["runtime_min"]["kraken2"]
    params:
        out_sample = OUT + "/kraken2/flye_assembly/{sample}/{sample}",
        kraken2_db = config["db_dir"],
    log:
        OUT + "/log/kraken2/{sample}-flye.log"
    benchmark:
        OUT + "/log/kraken2/kraken2_{sample}-flye.txt"
    shell: 
        """
        kraken2 --threads 4 \
        --db {params.kraken2_db} \
        --classified-out {params.out_sample}_classified_assembly.txt \
        --unclassified-out {params.out_sample}_unclassified_assembly.txt \
        --report {output.kraken2_kreport} \
        --output - \
        {input.assembly}

        bracken -d {params.kraken2_db} \
        -i {output.kraken2_kreport} \
        -o {output.bracken_s} \
        -r 150 \
        -l S \
        -t 0  &>> {log} 

        """

rule top_species_multireport:
    input:
        expand(
            OUT + "/kraken2/flye_assembly/{sample}/{sample}_species_content.txt",
            sample=SAMPLES,
        ),
    output:
        OUT + "/identify_species/top1_species_multireport.csv",
    message:
        "Generating multireport for spcies identification."
    log:
        OUT + "/log/identify_species/multireport.log",
    threads: config["threads"]["parsing"]
    resources:
        mem_gb=config["mem_gb"]["parsing"],
    shell:
        """
        python workflow/scripts/make_summary_main_species.py --input-files {input} \
                                                --output-multireport {output} > {log}
        """