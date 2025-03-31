rule kraken2:
    input:
        gz_filtlong = OUT + "/gz/filtlong/{sample}_min1000_best" + config["keep_percent_str"] + ".fastq.gz",
        assembly = OUT + "/{assembler}/{sample}/assembly/assembly.fasta" # Can be the unedited raw fasta file
    output:
        read_report = OUT + "/kraken2/{assembler}/{sample}/{sample}_read-report.txt",
        assembly_report = OUT + "/kraken2/{assembler}/{sample}/{sample}_assembly-report.txt"
    conda:
        "envs/kraken2.yaml"
    threads: config["threads"]["kraken2"]
    resources: 
        max_mb = config["max_mb"]["kraken2"],
        mem_mb = config["mem_mb"]["kraken2"],
        runtime_min = config["runtime_min"]["kraken2"]
    params:
        out_sample = OUT + "/kraken2/{assembler}/{sample}/{sample}",
        kraken2_db = config["db_dir"],
    log:
        OUT + "/log/kraken2/{sample}-{assembler}.log"
    benchmark:
        OUT + "/log/kraken2/kraken2_{sample}-{assembler}.txt"
    shell: 
        """
echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
kraken2 \
        --threads 4 \
        --db {params.kraken2_db} \
        --gzip-compressed \
        --classified-out {params.out_sample}_classified_reads.txt \
        --unclassified-out {params.out_sample}_unclassified_reads.txt \
        --report {output.read_report} \
        --output - \
        {input.gz_filtlong}
kraken2 \
        --threads 4 \
        --db {params.kraken2_db} \
        --classified-out {params.out_sample}_classified_assembly.txt \
        --unclassified-out {params.out_sample}_unclassified_assembly.txt \
        --report {output.assembly_report} \
        --output - \
        {input.assembly}
        """