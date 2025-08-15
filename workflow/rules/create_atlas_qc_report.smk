rule create_atlas_QC_report:
    input:
        species=OUT + "/kraken2/consensus_assembly/top1_species_multireport.csv",
        phred=OUT + "/nanoplot/NanoStats_summary.tsv",
        fastp=OUT + "/fastplong/fastplong_summary.tsv",
        quast=OUT + "/qc_consensus_assembly/quast/transposed_report.tsv",
        checkm=OUT + "/qc_consensus_assembly/checkm/checkm_report.tsv",
        genome_size=expand(OUT + "/autocycler/{sample}/genome_size.txt", sample=SAMPLES),
    output:
        OUT + "/Atlas_assembly_QC_report/QC_report.xlsx",
    message:
        "Creating Atlas assembly QC report."
    threads: config["threads"]["default"]
    resources:
        mem_gb=config["mem_gb"]["default"],
    log:
        OUT + "/log/create_atlas_QC_report.log",
    script:
        "../scripts/create_atlas_qc_report.py"