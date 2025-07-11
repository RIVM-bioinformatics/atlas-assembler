rule select_genus_checkm:
    input:
        genus_bracken=OUT + "/kraken2/consensus_assembly/{sample}/{sample}_bracken_species.kreport2",
        list_accepted_genera="files/accepted_genera_checkm.txt",
    output:
        selected_genus=OUT
        + "/qc_consensus_assembly/checkm/per_sample/{sample}/selected_genus.txt",
    message:
        "Selecting genus for CheckM for {wildcards.sample}."
    threads: config["threads"]["checkm"]
    resources:
        mem_gb=config["mem_gb"]["checkm"],
    params:
        genus=lambda wildcards: SAMPLES[wildcards.sample]["genus"],
    log:
        OUT + "/log/qc_consensus_assembly/select_genus_checkm_{sample}.log",
    shell:
        """
        python workflow/scripts/select_genus_checkm.py \
        --genus {params.genus} \
        --bracken-output {input.genus_bracken} \
        --output {output.selected_genus} 2>&1>{log}
        """

rule checkm:
    input:
        assembly=OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta",
        selected_genus=OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/selected_genus.txt",
    output:
        result=OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/checkm_{sample}.tsv",
        tmp_dir1=temp(directory(OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/bins")),
        tmp_dir2=temp(directory(OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/storage")),
    message:
        "Running CheckM for {wildcards.sample}."
    conda:
        "../../envs/checkm.yaml"
    threads: config["threads"]["checkm"]
    resources:
        mem_gb=config["mem_gb"]["checkm"],
    params:
        input_dir=OUT + "/autocycler/all_consensus_assembly/",
        output_dir=OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}",
    log:
        OUT + "/log/qc_consensus_assembly/checkm_{sample}.log",
    shell:
        """
       
        checkm taxonomy_wf genus "$(<{input.selected_genus})" \
            {params.input_dir} \
            {params.output_dir} \
            -t {threads} \
            -x fasta > {output.result}
        mv {params.output_dir}/checkm.log {log}
    
        """