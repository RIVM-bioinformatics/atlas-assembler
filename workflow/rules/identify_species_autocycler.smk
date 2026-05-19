rule identify_species_reads:
    input:
        # lambda wildcards: SAMPLES[wildcards.sample]["nanopore_input"],
        # chopper_fastq=OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz",
        filtered = OUT + "/fastplong/{sample}.fastq",
    output:
        # read_report = OUT + "/kraken2/flye/{sample}/{sample}_read-report.txt",
        kraken2_kreport = OUT + "/identify_species/reads/{sample}/{sample}.kreport2",
        bracken_s = OUT + "/identify_species/reads/{sample}/{sample}_species_content.txt",
        bracken_kreport=OUT + "/identify_species/reads/{sample}/{sample}_bracken_species.kreport2",
    conda:
        "../../envs/identify_species.yaml"
    threads: int(config["threads"]["kraken2"])
    resources:
        mem_gb = config["mem_gb"]["kraken2"],
        # runtime_min = config["runtime_min"]["kraken2"]
    params:
        out_sample = OUT + "/identify_species/reads/{sample}/{sample}",
        kraken2_db = config["db_dir"],
    log:
        OUT + "/log/identify_species/{sample}-reads.log"
    benchmark:
        OUT + "/log/identify_species/kraken2_{sample}-reads.txt"
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

# rule identify_species:
#     input:
#         assembly = OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta", 
#     output:
#         # read_report = OUT + "/kraken2/flye/{sample}/{sample}_read-report.txt",
#         kraken2_kreport = OUT + "/identify_species/consensus_assembly/{sample}/{sample}.kreport2",
#         bracken_s = OUT + "/identify_species/consensus_assembly/{sample}/{sample}_species_content.txt",
#         bracken_kreport=OUT + "/identify_species/consensus_assembly/{sample}/{sample}_bracken_species.kreport2",
#     conda:
#         "../../envs/identify_species.yaml"
#     threads: int(config["threads"]["kraken2"])
#     resources:
#         mem_gb = config["mem_gb"]["kraken2"],
#         # runtime_min = config["runtime_min"]["kraken2"]
#     params:
#         out_sample = OUT + "/identify_species/consensus_assembly/{sample}/{sample}",
#         kraken2_db = config["db_dir"],
#     log:
#         OUT + "/log/identify_species/{sample}-consensus.log"
#     benchmark:
#         OUT + "/log/identify_species/kraken2_{sample}-consensus.txt"
#     shell: 
#         """
#         kraken2 --threads 4 \
#         --db {params.kraken2_db} \
#         --classified-out {params.out_sample}_classified_assembly.txt \
#         --unclassified-out {params.out_sample}_unclassified_assembly.txt \
#         --report {output.kraken2_kreport} \
#         --output - \
#         {input.assembly}

#         bracken -d {params.kraken2_db} \
#         -i {output.kraken2_kreport} \
#         -o {output.bracken_s} \
#         -r 150 \
#         -l S \
#         -t 0  &>> {log} 

#         """

rule identify_species:
    input:
        assembly = OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta", 
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        # read_report = OUT + "/kraken2/flye/{sample}/{sample}_read-report.txt",
        kraken2_kreport = OUT + "/identify_species/consensus_assembly/{sample}/{sample}.kreport2",
        bracken_s = OUT + "/identify_species/consensus_assembly/{sample}/{sample}_species_content.txt",
        bracken_kreport=OUT + "/identify_species/consensus_assembly/{sample}/{sample}_bracken_species.kreport2",
        
    conda:
        "../../envs/identify_species.yaml"
    threads: int(config["threads"]["kraken2"])
    resources:
        mem_gb = config["mem_gb"]["kraken2"],
        # runtime_min = config["runtime_min"]["kraken2"]
    params:
        out_sample = OUT + "/identify_species/consensus_assembly/{sample}/{sample}",
        kraken2_db = config["db_dir"],
    log:
        OUT + "/log/identify_species/{sample}-consensus.log"
    benchmark:
        OUT + "/log/identify_species/kraken2_{sample}-consensus.txt"
    shell: 
        """
        if [ $(< {input.flag}) == "sufficient" ]; then
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
        else
            echo "Unable to run Kraken as coverage is less than 30 x" > {output.kraken2_kreport}
            echo "Unable to run Bracken as coverage is less than 30 x" > {output.bracken_s}
            echo "Unable to run Bracken as coverage is less than 30 x" > {output.bracken_kreport}

        fi
        """


rule identify_species_skani:
    input:
        assembly = expand(OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta", sample=SAMPLES),
    output:
        OUT + "/identify_species/skani_results.tsv",
    message:
        "Generating skani report."
    conda:
        "../../envs/skani.yaml"
    # container:
    #     "docker://quay.io/biocontainers/skani:0.2.2--ha6fb395_2"
    threads: config["threads"]["skani"]
    resources:
        mem_gb=config["mem_gb"]["skani"],
    log:
        OUT + "/log/identify_species/skani_report.log",
    params:
        max_no_hits=config["skani_max_no_hits"],
        gtdb_db_dir=config["skani_gtdb_db_dir"],
    shell:
        """
skani search {input.assembly} \
    -o {output} \
    -d {params.gtdb_db_dir} \
    --ci \
    -n {params.max_no_hits} >> {log} 2>&1
        """