import yaml
import os
import glob
import json

rule determine_genome_size:
    input:
        lambda wildcards: SAMPLES[wildcards.sample]["nanopore_input"],
    output:
        OUT + "/autocycler/{sample}/genome_size.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["genome_size"] # 8
    resources: 
        mem_gb = config["mem_gb"]["genome_size"], # 48
        run_time_minutes = config["run_time_minutes"]["genome_size"] # 60
    params:
        outdir_sample = OUT + "/autocycler/{sample}"
    log:
        OUT + "/log/autocycler/{sample}/determine_genome_size.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/determine_genome_size.txt"
    shell:
        """
       workflow/scripts/genome_size_raven.sh {input}/*fastq* {threads} >> {params.outdir_sample}/genome_size.txt
        """

checkpoint check_coverage:
    input:
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt",
        fastplong_json = OUT + "/fastplong/{sample}.json",
    output:
        flag=OUT + "/coverage/{sample}_coverage_flag.txt",
    resources:
        mem_gb=config["mem_gb"]["default"],
    run:
        # Read genome size
        with open(input.genome_size) as f:
            genome_size = float(f.read().strip())

        # Read total_bases after filtering from JSON
        with open(input.fastplong_json) as f:
            fastplong_data = json.load(f)
            total_bases = fastplong_data["summary"]["after_filtering"]["total_bases"]

        coverage = round(total_bases / genome_size)

        if coverage > 30:
            flag = "sufficient"
        else:
            flag = "low"
        with open(output.flag, "w") as f:
            f.write(flag)

rule autocycler_subsample:
    input:
        fastq = lambda wildcards: glob.glob(
            os.path.join(SAMPLES[wildcards.sample]["nanopore_input"], "*.fastq*")
        )[0],
        filtered = OUT + "/fastplong/{sample}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output: # This is the only part that is essentially hardcoded because this says you explicitly use 4 subsets - You'd have to script the output otherwise and multiply by n of subsets used.
        sample_01 = temp(OUT + "/autocycler/{sample}/subsampled_reads/sample_01.fastq"),
        sample_02 = temp(OUT + "/autocycler/{sample}/subsampled_reads/sample_02.fastq"),
        sample_03 = temp(OUT + "/autocycler/{sample}/subsampled_reads/sample_03.fastq"),
        sample_04 = temp(OUT + "/autocycler/{sample}/subsampled_reads/sample_04.fastq"),
        completed = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        outdir_sample = OUT + "/autocycler/{sample}",
        subsample_dir = OUT + "/autocycler/{sample}/subsampled_reads/",
    log:
        OUT + "/log/autocycler/{sample}/subsample.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/subsample.txt"
    shell:
        """
genome_size=$(<{input.genome_size})

if [ $(< {input.flag}) == "sufficient" ]; then
    autocycler subsample --reads {input.filtered} --out_dir {params.outdir_sample}/subsampled_reads --genome_size ${{genome_size}} \
    && echo "Continue to run Autocycler" > {output.completed}
else
    mkdir -p {params.subsample_dir}
    echo "Unable to run Autocycler as coverage is $coverage x which is less than 30 x" > {output.completed}
    touch {output.sample_01} {output.sample_02} {output.sample_03} {output.sample_04}
fi 
        """

# rule autocycler_canu:
#     input:
#         fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
#         genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
#     output:
#         OUT + "/autocycler/{sample}/assemblies/canu_{sample}_{subset}.fasta"
#     conda:
#         "../../envs/autocycler.yaml"
#     threads: config["threads"]["canu"] # 18
#     resources: 
#         mem_gb = config["mem_gb"]["canu"], # 24
#         run_time_minutes = config["run_time_minutes"]["canu"] # 600
#     params:
#         tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
#         tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/canu_{sample}_{subset}",
#         assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
#         evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
#     log:
#         OUT + "/log/autocycler/{sample}/canu_{sample}_{subset}.log"
#     benchmark:
#         OUT + "/log/benchmark/autocycler/{sample}/canu_{sample}_{subset}.txt"
#     shell:
#         """
# read -r checkpoint _ < {params.evaluation_file}
# if [[ "$checkpoint" == "Continue" ]]
# then
#     export PATH=$PATH:workflow/scripts
#     genome_size=$(<{input.genome_size})
#     mkdir -p {params.tmp_fasta_dir}
#     workflow/scripts/canu.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
#     sleep 30 && \
#     mkdir -p {params.assembly_dir} && \
#     cp {params.tmp_fasta_name}.fasta {output}
# else
#     mkdir -p {params.assembly_dir}
#     touch {output}
# fi
#         """

rule autocycler_flye:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
    output:
        OUT + "/autocycler/{sample}/assemblies/flye_{sample}_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["flye"] # 8
    resources: 
        mem_gb = config["mem_gb"]["flye"], # 16
        run_time_minutes = lambda wildcards, attempt: determine_runtime(wildcards, attempt, config["run_time_minutes"]["flye"]),
        retry_count = lambda wildcards, attempt=1: determine_final_try(wildcards, attempt)
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/flye_{sample}_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
        evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/flye_{sample}_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/flye_{sample}_{subset}.txt"
    shell:
        """
    read -r checkpoint _ < {params.evaluation_file}
    if [[ "$checkpoint" == "Continue" ]]
    then
        echo "Evaluating to run Flye"
        if [ {resources.retry_count} == 4 ]; then 
            if [ ! -f {output} ]; then 
                touch {output} 
            fi 
        else 
            genome_size=$(<{input.genome_size})
            mkdir -p {params.tmp_fasta_dir}
            workflow/scripts/flye.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
            sleep 30 && \
            mkdir -p {params.assembly_dir} && \
            cp {params.tmp_fasta_name}.fasta {output}
        fi
    else
        mkdir -p {params.assembly_dir}
        touch {output}
    fi
        """

rule autocycler_miniasm:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        OUT + "/autocycler/{sample}/assemblies/miniasm_{sample}_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["miniasm"] # 8
    resources: 
        mem_gb = config["mem_gb"]["miniasm"], # 16
        run_time_minutes = config["run_time_minutes"]["miniasm"] # 60
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/miniasm_{sample}_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/miniasm_{sample}_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/miniasm_{sample}_{subset}.txt"
    shell:
        """
if [ $(< {input.flag}) == "sufficient" ];
then
    genome_size=$(<{input.genome_size})
    mkdir -p {params.tmp_fasta_dir}
    workflow/scripts/miniasm.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
    sleep 30 && \
    mkdir -p {params.assembly_dir} && \
    cp {params.tmp_fasta_name}.fasta {output}
else
    mkdir -p {params.assembly_dir}
    touch {output}
fi
        """

# rule autocycler_necat:
#     input:
#         fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
#         genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
#     output:
#         OUT + "/autocycler/{sample}/assemblies/necat_{sample}_{subset}.fasta"
#     conda:
#         "../../envs/autocycler.yaml"
#     threads: lambda wildcards, attempt: determine_threads(wildcards, attempt, config["threads"]["necat"]) 
#     resources: 
#         mem_gb = config["mem_gb"]["necat"], # 24
#         run_time_minutes = config["run_time_minutes"]["necat"], # 60
#         retry_count = lambda wildcards, attempt=1: determine_final_try(wildcards, attempt)
#     params:
#         tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
#         tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/necat_{sample}_{subset}",
#         assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
#         evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
#     log:
#         OUT + "/log/autocycler/{sample}/necat_{sample}_{subset}.log"
#     benchmark:
#         OUT + "/log/benchmark/autocycler/{sample}/necat_{sample}_{subset}.txt"
#     shell:
#         """
# read -r checkpoint _ < {params.evaluation_file}
# if [[ "$checkpoint" == "Continue" ]]
# then
#     if [ {resources.retry_count} -le 4 ]; then
#         if [ ! -f {output} ]; then
#             touch {output}
#         fi
#     else
#         genome_size=$(<{input.genome_size})
#         mkdir -p {params.tmp_fasta_dir}
#         workflow/scripts/necat.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
#         sleep 30 && \
#         mkdir -p {params.assembly_dir} && \
#         cp {params.tmp_fasta_name}.fasta {output}
#     fi
# else
#     mkdir -p {params.assembly_dir}
#     touch {output}
# fi
#         """

rule autocycler_nextdenovo:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
    output:
        OUT + "/autocycler/{sample}/assemblies/nextdenovo_{sample}_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["nextdenovo"] # 8
    resources: 
        mem_gb = config["mem_gb"]["nextdenovo"], # 12
        run_time_minutes = config["run_time_minutes"]["nextdenovo"] # 60
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/nextdenovo_{sample}_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
        evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/nextdenovo_{sample}_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/nextdenovo_{sample}_{subset}.txt"
    shell:
        """
read -r checkpoint _ < {params.evaluation_file}
if [[ "$checkpoint" == "Continue" ]]
then
    genome_size=$(<{input.genome_size})
    mkdir -p {params.tmp_fasta_dir}
    workflow/scripts/nextdenovo.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
    sleep 30 && \
    mkdir -p {params.assembly_dir} && \
    cp {params.tmp_fasta_name}.fasta {output}
else
    mkdir -p {params.assembly_dir}
    touch {output}
fi
        """

rule autocycler_raven:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        OUT + "/autocycler/{sample}/assemblies/raven_{sample}_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["raven"] # 8
    resources: 
        # mem_gb = config["mem_gb"]["raven"], # 12
        retry_count = lambda wildcards, attempt=1: determine_final_try(wildcards, attempt),
        mem_gb = lambda wildcards, attempt: determine_memory(wildcards, attempt, config["mem_gb"]["raven"]), # 12
        run_time_minutes = config["run_time_minutes"]["raven"], # 60
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/raven_{sample}_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/raven_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/raven_{sample}_{subset}.txt"
    shell:
        """
    if [ $(< {input.flag}) == "sufficient" ];
    then
        if [ {resources.retry_count} == 4 ]; then 
            if [ ! -f {output} ]; then 
                touch {output} 
            fi 
        else
            genome_size=$(<{input.genome_size})
            mkdir -p {params.tmp_fasta_dir}
            workflow/scripts/raven.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
            sleep 30 && \
            mkdir -p {params.assembly_dir} && \
            cp {params.tmp_fasta_name}.fasta {output}
        fi
    else
        mkdir -p {params.assembly_dir}
        touch {output}
    fi

        """

rule autocycler_collect: 
    input:
        all_fasta = expand([OUT + "/autocycler/{{sample}}/assemblies/{assembler}_{{sample}}_{subset}.fasta"], assembler = assembler_list, subset = subsets_used),
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        OUT + "/autocycler/{sample}/assemblies_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 5
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/collect.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/collect.txt"
    shell:
        """
if [ $(< {input.flag}) == "sufficient" ];
then
    for fasta in {input.all_fasta} ; do
        if [ -f "${{fasta}}" ] && [ ! -s "${{fasta}}" ]; then
            echo "Removing empty file: ${{fasta}}" >> {log}
            rm "${{fasta}}"
        fi
    done
    python workflow/scripts/clean_assembly_dir.py --directory {params.assembly_dir} --genome_size {input.genome_size} >> {log} && \ 
    sleep 10
    touch {output}
else
    touch {output}
fi
        """


rule autocycler_compress:
    input:
        assembly_file = OUT + "/autocycler/{sample}/assemblies_completed.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        compress = OUT + "/autocycler/{sample}/compress_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["autocycler_compress"] # 4
    resources: 
        mem_gb = config["mem_gb"]["autocycler_compress"], # 16
        run_time_minutes = config["run_time_minutes"]["autocycler_compress"] # 30
    params:
        # autocycler_exe = config["autocycler_executable"],
        autocycler_dir = OUT + "/autocycler/{sample}/autocycler_out/",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
        autocycler_fasta = OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta",
        autocycler_counter = OUT + "/autocycler/{sample}/autocycler_attempt_counter.txt",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"

    log:
        OUT + "/log/autocycler/{sample}/compress.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/compress.txt"
    shell:
        """
if [ $(< {input.flag}) == "sufficient" ];
then
    # Track iteration
    iteration=1
    if [ -f {params.autocycler_counter} ]; then
        iteration=$(($(cat {params.autocycler_counter}) + 1))
        rm -fr {params.autocycler_dir}/*
    fi
    autocycler compress -i {params.assembly_dir} -a {params.autocycler_dir} -t {threads} \
    && touch {output.compress}
    echo $iteration > {params.autocycler_counter}
else
    touch {output}
fi
        """


rule autocycler_cluster:
    input:
        compress = OUT + "/autocycler/{sample}/compress_completed.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        OUT + "/autocycler/{sample}/cluster_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        autocycler_dir = OUT + "/autocycler/{sample}/autocycler_out/",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/cluster.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/cluster.txt"
    shell:
       """
if [ $(< {input.flag}) == "sufficient" ];
then
    autocycler cluster -a {params.autocycler_dir} \
    && touch {output}
else
    touch {output}
fi
        """


rule autocycler_trim:
    input:
        OUT + "/autocycler/{sample}/cluster_completed.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        OUT + "/autocycler/{sample}/trim_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        autocycler_qc_pass_dir = OUT + "/autocycler/{sample}/autocycler_out/clustering/qc_pass",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/trim.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/trim.txt"
    shell:
       """
if [ $(< {input.flag}) == "sufficient" ];
then
    for c in {params.autocycler_qc_pass_dir}/cluster_*; do
    autocycler trim -c ${{c}}
    done \
    && touch {output}
else
    touch {output}
fi
        """


rule autocycler_resolve:
    input:
        OUT + "/autocycler/{sample}/trim_completed.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        OUT + "/autocycler/{sample}/resolve_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        autocycler_qc_pass_dir = OUT + "/autocycler/{sample}/autocycler_out/clustering/qc_pass",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/resolve.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/resolve.txt"
    shell:
        """
if [ $(< {input.flag}) == "sufficient" ];
then
    for c in {params.autocycler_qc_pass_dir}/cluster_*; do
    autocycler resolve -c ${{c}}
    done \
    && touch {output}
else
    touch {output}
fi
        """

rule autocycler_combine:
    input:
        OUT + "/autocycler/{sample}/resolve_completed.txt",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        fasta = OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta",
        gfa = OUT + "/autocycler/{sample}/autocycler_out/consensus_assembly.gfa"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        autocycler_dir = OUT + "/autocycler/{sample}/autocycler_out/",
        autocycler_qc_pass_dir = OUT + "/autocycler/{sample}/autocycler_out/clustering/qc_pass",
        tmp_final_name = OUT + "/autocycler/{sample}/autocycler_out/consensus_assembly.fasta",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/combine.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/combine.txt"
    shell:
       """
if [ $(< {input.flag}) == "sufficient" ];
then
    autocycler combine -a {params.autocycler_dir} -i {params.autocycler_qc_pass_dir}/cluster_*/5_final.gfa && \
    sleep 30 && \
    cp {params.tmp_final_name} {output.fasta}
else
    touch {output.fasta} {output.gfa}
fi
        """

rule autocycler_completed:
    input:
        fasta = OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta",
        gfa = OUT + "/autocycler/{sample}/autocycler_out/consensus_assembly.gfa",
        flag=lambda wildcards: checkpoints.check_coverage.get(sample=wildcards.sample).output.flag,
    output:
        OUT + "/autocycler/{sample}/autocycler_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        autocycler_counter = OUT + "/autocycler/{sample}/autocycler_attempt_counter.txt",
        backup_dir = OUT + "/autocycler/{sample}/backup",
        autocycler_dir = OUT + "/autocycler/{sample}/autocycler_out",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/",
        genome_size = OUT + "/autocycler/{sample}/genome-size.txt",
        percentage = 55, # starting percentage, up by 10% each try
        autocycler_rerun_flag = OUT + "/autocycler/{sample}/rerun_autocycler_flag.txt",
        output_resolve = OUT + "/autocycler/{sample}/resolve_completed.txt",
        output_trim = OUT + "/autocycler/{sample}/trim_completed.txt",
        output_cluster = OUT + "/autocycler/{sample}/cluster_completed.txt",
        output_compress = OUT + "/autocycler/{sample}/compress_completed.txt",
        # evaluation_file = OUT + "/autocycler/{sample}/subsampled_reads_completed.txt"
    log:
        OUT + "/log/autocycler/{sample}/completed.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/completed.txt"
    shell: # Should probably put logic below inside a single .py or .sh script
        """
if [ $(< {input.flag}) == "sufficient" ];
then
    counter=$(<{params.autocycler_counter})
    percentage=$(( (${{counter}} - 1) * 10 + {params.percentage} )) 
    set +e
    python workflow/scripts/assess_autocycler.py --input {input.fasta} --directory {params.assembly_dir} --genome_size {params.genome_size} --percentage ${{percentage}}
    exit_code=$?
    echo $exit_code
    set -e
    if [[ $exit_code -eq 4 ]]; then
        rm -f {params.autocycler_rerun_flag} # rm so bash will also exit the while loop
        echo "Continue to rename, however, no fasta files would be left to retry autocycler steps, tried ${{counter}} times... exiting..." | tee {output} >(tee -a {log})
        exit 0 # Use 'Continue' in echo above so the initial fasta file created by Autocycler will still be renamed by next rule.
    fi
    if [[ $exit_code -eq 42 ]]; then
        if [ ${{counter}} -gt 5 ]; then
            rm -f {params.autocycler_rerun_flag} # rm so bash will also exit the while loop
            echo "Tried rerunning autocycler steps ${{counter}} times... exiting..." | tee {output} >(tee -a {log} > {params.evaluation_file}) # Overwrite evalutation file so the (final) rename rule will also be escaped correctly, but keep program versions from log
            exit 0 # Ensure Snakemake does NOT treat it as an error
        else
            echo "🚨 Rerun triggered! Deleting outputs and exiting!"
            echo "rerun" > {params.autocycler_rerun_flag}
            echo "Rerun initiated, will delete subset assemblies where largest contig size is less than ${{percentage}}%. See logs for details." | tee {output} >(tee -a {log}); sleep 10
            mkdir -p {params.backup_dir} && \
            cp {input.fasta} {params.backup_dir}/consensus_assembly-${{counter}}.fasta && \
            cp {input.gfa} {params.backup_dir}/consensus_assembly-${{counter}}.gfa && \
            rm -f {params.output_resolve} {params.output_trim} {params.output_cluster} {params.output_compress}
            exit 0 # ❌ Finish without error but will rerun in the shell that initially called Snakemake
        fi
    else
        if [ -f {params.autocycler_rerun_flag} ]; then
            rm -f {params.autocycler_rerun_flag}
        fi
        echo "✅ Autocycler Atlas complete!" | tee {output} >(tee -a {log})
        exit 0
    fi
else
    echo "🚨 Autocycler was unable to run due to low coverage!" | tee {output} >(tee -a {log})
fi
        """
