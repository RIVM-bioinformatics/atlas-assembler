rule pycoqc:
    input:
        config["sequencing_summary"]
    output:
        OUT + "/pycoqc/sequencing_summary.html"
    conda:
        "envs/amr_longread.yaml"
    threads: config["threads"]["pycoqc"]
    resources: 
        mem_mb=lambda wildcards, attempt: config["mem_mb"]["pycoqc"] * attempt,
        max_mb=lambda wildcards, attempt: config["max_mb"]["pycoqc"] * attempt,
        runtime_min = config["runtime_min"]["pycoqc"]
    params:
        mockfile = OUT + "/irods_files/no_sequencing_summary.html" # touch this if non-irods mode is used.
    log:
        OUT + "/log/pycoqc/pycoqc.log"
    benchmark:
        OUT + "/log/benchmark/pycoqc.txt"
    shell:
        """
echo $'\n====================================\n==     PROGRAM VERSIONS USED      ==\n====================================\n' >> {log}; conda list >> {log}
if [ -f {params.mockfile} ]
then
    touch {output}
else
    pycoQC --summary_file {input} \
            -o {output}
fi
        """