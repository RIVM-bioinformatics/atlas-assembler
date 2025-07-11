rule parse_checkm:
    input:
        expand(
            OUT
            + "/qc_consensus_assembly/checkm/per_sample/{sample}/checkm_{sample}.tsv",
            sample=SAMPLES,
        ),
    output:
        OUT + "/qc_consensus_assembly/checkm/checkm_report.tsv",
    message:
        "Parsing the results of CheckM and making a multireport."
    threads: config["threads"]["parsing"]
    resources:
        mem_gb=config["mem_gb"]["parsing"],
    log:
        OUT + "/log/checkm/checkm_combined.log",
    script:
        "../../parse_checkM.py"