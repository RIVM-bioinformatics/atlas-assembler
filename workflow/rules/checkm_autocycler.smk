# rule select_genus_checkm:
#     input:
#         genus_bracken=OUT + "/identify_species/consensus_assembly/{sample}/{sample}_bracken_species.kreport2",
#         list_accepted_genera="files/accepted_genera_checkm.txt",
#     output:
#         selected_genus=OUT
#         + "/qc_consensus_assembly/checkm/per_sample/{sample}/selected_genus.txt",
#     message:
#         "Selecting genus for CheckM for {wildcards.sample}."
#     threads: config["threads"]["checkm"]
#     resources:
#         mem_gb=config["mem_gb"]["checkm"],
#     params:
#         genus=lambda wildcards: SAMPLES[wildcards.sample]["genus"],
#     log:
#         OUT + "/log/qc_consensus_assembly/select_genus_checkm_{sample}.log",
#     shell:
#         """
#         python workflow/scripts/select_genus_checkm.py \
#         --genus {params.genus} \
#         --bracken-output {input.genus_bracken} \
#         --output {output.selected_genus} 2>&1>{log}
#         """

rule select_genus_checkm:
    input:
        genus_bracken=OUT + "/identify_species/consensus_assembly/{sample}/{sample}_bracken_species.kreport2",
        list_accepted_genera="files/accepted_genera_checkm.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,    
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
        if [ $(< {input.flag}) == "sufficient" ]; then
            python workflow/scripts/select_genus_checkm.py \
            --genus {params.genus} \
            --bracken-output {input.genus_bracken} \
            --output {output.selected_genus} 2>&1>{log}
        else
            echo "Not enough coverage to select genus for CheckM" > {output.selected_genus}
        fi
            """

# rule checkm:
#     input:
#         assembly=OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta",
#         selected_genus=OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/selected_genus.txt",
#     output:
#         result=OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/checkm_{sample}.tsv",
#         tmp_dir1=temp(directory(OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/bins")),
#         tmp_dir2=temp(directory(OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/storage")),
#     message:
#         "Running CheckM for {wildcards.sample}."
#     conda:
#         "../../envs/checkm.yaml"
#     threads: config["threads"]["checkm"]
#     resources:
#         mem_gb=config["mem_gb"]["checkm"],
#     params:
#         input_dir=OUT + "/autocycler/all_consensus_assembly/",
#         output_dir=OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}",
#     log:
#         OUT + "/log/qc_consensus_assembly/checkm_{sample}.log",
#     shell:
#         """
       
#         checkm taxonomy_wf genus "$(<{input.selected_genus})" \
#             {params.input_dir} \
#             {params.output_dir} \
#             -t {threads} \
#             -x fasta > {output.result}
#         mv {params.output_dir}/checkm.log {log}
    
#         """

rule checkm:
    input:
        assembly=OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta",
        selected_genus=OUT + "/qc_consensus_assembly/checkm/per_sample/{sample}/selected_genus.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
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
        mkdir -p {params.output_dir}
        # ensure tmp output dirs exist even for low-coverage branch so Snakemake sees them
        mkdir -p {output.tmp_dir1} {output.tmp_dir2}

        if [ "$(cat {input.flag})" = "sufficient" ]; then
            checkm taxonomy_wf genus "$(<{input.selected_genus})" \
                {params.input_dir} \
                {params.output_dir} \
                -t {threads} \
                -x fasta > {output.result} 2>> {log}
            mv {params.output_dir}/checkm.log {log} || true
        else
            echo "Not enough coverage to run CheckM" > {output.result}
        fi
        """