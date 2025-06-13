import yaml
import os
import glob

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

rule autocycler_subsample:
    input:
        # fastq = OUT + "/fastq/chopper/unfiltered_{sample}.fastq",
        fastq = lambda wildcards: glob.glob(
            os.path.join(SAMPLES[wildcards.sample]["nanopore_input"], "*.fastq*")
        )[0],
        # fastq = lambda wildcards: SAMPLES[wildcards.sample]["nanopore_input"],
        gz_chopper = OUT + "/gz/chopper/{sample}_min" + config["length"] + ".fastq.gz",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
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
        outdir_sample = OUT + "/autocycler/{sample}"
    log:
        OUT + "/log/autocycler/{sample}/subsample.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/subsample.txt"
    shell:
        """
genome_size=$(<{input.genome_size})
autocycler subsample --reads {input.fastq} --out_dir {params.outdir_sample}/subsampled_reads --genome_size ${{genome_size}} \
&& touch {output.completed}
        """

rule autocycler_canu:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
    output:
        OUT + "/autocycler/{sample}/assemblies/canu_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["canu"] # 18
    resources: 
        mem_gb = config["mem_gb"]["canu"], # 24
        run_time_minutes = config["run_time_minutes"]["canu"] # 600
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/canu_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/"
    log:
        OUT + "/log/autocycler/{sample}/canu_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/canu_{subset}.txt"
    shell:
        """
genome_size=$(<{input.genome_size})
mkdir -p {params.tmp_fasta_dir}
canu.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
sleep 30 && \
mkdir -p {params.assembly_dir} && \
cp {params.tmp_fasta_name}.fasta {output}
        """

rule autocycler_flye:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
    output:
        OUT + "/autocycler/{sample}/assemblies/flye_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["flye"] # 8
    resources: 
        mem_gb = config["mem_gb"]["flye"], # 16
        run_time_minutes = lambda wildcards, attempt: determine_runtime(wildcards, attempt, config["run_time_minutes"]["flye"]),
        retry_count = lambda wildcards, attempt=1: determine_final_try(wildcards, attempt)
        # retry_count = determine_final_try
        # runtime_min = config["runtime_min"]["flye"] # 60
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/flye_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/"
    log:
        OUT + "/log/autocycler/{sample}/flye_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/flye_{subset}.txt"
    shell:
        """
if [ {resources.retry_count} == 4 ]; then 
    if [ ! -f {output} ]; then 
        touch {output} 
    fi 
else 
    genome_size=$(<{input.genome_size})
    mkdir -p {params.tmp_fasta_dir}
    flye.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
    sleep 30 && \
    mkdir -p {params.assembly_dir} && \
    cp {params.tmp_fasta_name}.fasta {output}
fi
        """

rule autocycler_miniasm:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
    output:
        OUT + "/autocycler/{sample}/assemblies/miniasm_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["miniasm"] # 8
    resources: 
        mem_gb = config["mem_gb"]["miniasm"], # 16
        run_time_minutes = config["run_time_minutes"]["miniasm"] # 60
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/miniasm_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/"
    log:
        OUT + "/log/autocycler/{sample}/miniasm_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/miniasm_{subset}.txt"
    shell:
        """
genome_size=$(<{input.genome_size})
mkdir -p {params.tmp_fasta_dir}
miniasm.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
sleep 30 && \
mkdir -p {params.assembly_dir} && \
cp {params.tmp_fasta_name}.fasta {output}
        """

rule autocycler_necat:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
    output:
        OUT + "/autocycler/{sample}/assemblies/necat_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["necat"] # 8
    resources: 
        mem_gb = config["mem_gb"]["necat"], # 24
        run_time_minutes = config["run_time_minutes"]["necat"] # 60
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/necat_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/"
    log:
        OUT + "/log/autocycler/{sample}/necat_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/necat_{subset}.txt"
    shell:
        """
genome_size=$(<{input.genome_size})
mkdir -p {params.tmp_fasta_dir}
necat.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
sleep 30 && \
mkdir -p {params.assembly_dir} && \
cp {params.tmp_fasta_name}.fasta {output}
        """

rule autocycler_nextdenovo:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
    output:
        OUT + "/autocycler/{sample}/assemblies/nextdenovo_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["nextdenovo"] # 8
    resources: 
        mem_gb = config["mem_gb"]["nextdenovo"], # 12
        run_time_minutes = config["run_time_minutes"]["nextdenovo"] # 60
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/nextdenovo_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/"
    log:
        OUT + "/log/autocycler/{sample}/nextdenovo_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/nextdenovo_{subset}.txt"
    shell:
        """
genome_size=$(<{input.genome_size})
mkdir -p {params.tmp_fasta_dir}
nextdenovo.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
sleep 30 && \
mkdir -p {params.assembly_dir} && \
cp {params.tmp_fasta_name}.fasta {output}
        """

rule autocycler_raven:
    input:
        fastq = OUT + "/autocycler/{sample}/subsampled_reads/sample_{subset}.fastq",
        genome_size = OUT + "/autocycler/{sample}/genome_size.txt"
    output:
        OUT + "/autocycler/{sample}/assemblies/raven_{subset}.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["raven"] # 8
    resources: 
        mem_gb = lambda wildcards, attempt: determine_memory(wildcards, attempt, config["mem_gb"]["raven"]), # 12
        run_time_minutes = config["run_time_minutes"]["raven"], # 60
        retry_count = lambda wildcards, attempt=1: determine_final_try(wildcards, attempt)
    params:
        tmp_fasta_dir = OUT + "/autocycler/{sample}/tmp_assemblies/",
        tmp_fasta_name = OUT + "/autocycler/{sample}/tmp_assemblies/raven_{subset}",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/"
    log:
        OUT + "/log/autocycler/{sample}/raven_{subset}.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/raven_{subset}.txt"
    shell:
        """
if [ {resources.retry_count} == 4 ]; then 
    if [ ! -f {output} ]; then 
        touch {output} 
    fi 
else
    genome_size=$(<{input.genome_size})
    mkdir -p {params.tmp_fasta_dir}
    raven.sh {input.fastq} {params.tmp_fasta_name} {threads} ${{genome_size}} && \
    sleep 30 && \
    mkdir -p {params.assembly_dir} && \
    cp {params.tmp_fasta_name}.fasta {output}
fi
        """

rule autocycler_collect: 
    input:
        expand([OUT + "/autocycler/{{sample}}/assemblies/{assembler}_{subset}.fasta"], assembler = assembler_list, subset = subsets_used)
    output:
        OUT + "/autocycler/{sample}/assemblies_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 5
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        workdir = OUT
    log:
        OUT + "/log/autocycler/{sample}/collect.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/collect.txt"
    shell:
        """
for fasta in {input} ; do
    if [ -f "${{fasta}}" ] && [ ! -s "${{fasta}}" ]; then
        echo "Removing empty file: ${{fasta}}" >> {log}
        rm "${{fasta}}"
    fi
done
sleep 30
touch {output}
        """

rule autocycler_compress:
    input:
        OUT + "/autocycler/{sample}/assemblies_completed.txt"
    output:
        OUT + "/autocycler/{sample}/compress_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        # autocycler_exe = config["autocycler_executable"],
        autocycler_dir = OUT + "/autocycler/{sample}/autocycler_out/",
        assembly_dir = OUT + "/autocycler/{sample}/assemblies/"
    log:
        OUT + "/log/autocycler/{sample}/compress.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/compress.txt"
    shell:
        """
autocycler compress -i {params.assembly_dir} -a {params.autocycler_dir} \
&& touch {output}
        """

rule autocycler_cluster:
    input:
        OUT + "/autocycler/{sample}/compress_completed.txt"
    output:
        OUT + "/autocycler/{sample}/cluster_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        # autocycler_exe = config["autocycler_executable"],
        autocycler_dir = OUT + "/autocycler/{sample}/autocycler_out/"
    log:
        OUT + "/log/autocycler/{sample}/cluster.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/cluster.txt"
    shell:
        """
autocycler cluster -a {params.autocycler_dir} \
&& touch {output}
        """

rule autocycler_trim:
    input:
        OUT + "/autocycler/{sample}/cluster_completed.txt"
    output:
        OUT + "/autocycler/{sample}/trim_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        # autocycler_exe = config["autocycler_executable"],
        autocycler_qc_pass_dir = OUT + "/autocycler/{sample}/autocycler_out/clustering/qc_pass"
    log:
        OUT + "/log/autocycler/{sample}/trim.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/trim.txt"
    shell:
        """
for c in {params.autocycler_qc_pass_dir}/cluster_*; do
autocycler trim -c ${{c}}
done \
&& touch {output}
        """

rule autocycler_resolve:
    input:
        OUT + "/autocycler/{sample}/trim_completed.txt"
    output:
        OUT + "/autocycler/{sample}/resolve_completed.txt"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        # autocycler_exe = config["autocycler_executable"],
        autocycler_qc_pass_dir = OUT + "/autocycler/{sample}/autocycler_out/clustering/qc_pass"
    log:
        OUT + "/log/autocycler/{sample}/resolve.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/resolve.txt"
    shell:
        """
for c in {params.autocycler_qc_pass_dir}/cluster_*; do
autocycler resolve -c ${{c}}
done \
&& touch {output}
        """

rule autocycler_combine:
    input:
        OUT + "/autocycler/{sample}/resolve_completed.txt"
    output:
        OUT + "/autocycler/all_consensus_assembly/{sample}-autocycler.fasta"
    conda:
        "../../envs/autocycler.yaml"
    threads: config["threads"]["default"] # 1
    resources: 
        mem_gb = config["mem_gb"]["default"], # 4
        run_time_minutes = config["run_time_minutes"]["default"] # 30
    params:
        # autocycler_exe = config["autocycler_executable"],
        autocycler_dir = OUT + "/autocycler/{sample}/autocycler_out/",
        autocycler_qc_pass_dir = OUT + "/autocycler/{sample}/autocycler_out/clustering/qc_pass",
        tmp_final_name = OUT + "/autocycler/{sample}/autocycler_out/consensus_assembly.fasta"
    log:
        OUT + "/log/autocycler/{sample}/combine.log"
    benchmark:
        OUT + "/log/benchmark/autocycler/{sample}/combine.txt"
    shell:
        """
autocycler combine -a {params.autocycler_dir} -i {params.autocycler_qc_pass_dir}/cluster_*/5_final.gfa && \
sleep 30 && \
cp {params.tmp_final_name} {output}
        """