import glob, os, argparse, shutil
from Bio import SeqIO
from Bio import SeqUtils
from pathlib import Path

# python bin/clean_assembly_dir.py -d /path/to/all_assemblies/ -g genome_size.txt
# -d /data/BioGrid/landmanf/data/longread_validation/run_2b_PAU55953/autocycler/PR0007_barcode78_11060659/assemblies -g /data/BioGrid/landmanf/data/longread_validation/run_2b_PAU55953/autocycler/PR0007_barcode78_11060659/genome-size.txt

arg = argparse.ArgumentParser()

arg.add_argument(
    "-d",
    "--directory",
    metavar="Name",
    help="Directory with all assembly output to check",
    type=str,
    required=True,
)

arg.add_argument(
    "-g",
    "--genome_size",
    metavar="Name",
    help="Path to text file containing value for exptected genome size",
    type=str,
    required=True,
)

flags = arg.parse_args()

def percentage_difference(a, b):
    return abs(a - b) / max(a, b) * 100

def determine_size(assembly_dir, genome_size):
    for fasta in glob.glob(f"{assembly_dir}/*.fasta"):
        total_genome_size = sum(len(record.seq) for record in SeqIO.parse(fasta, "fasta"))
        perc_diference = percentage_difference(int(genome_size), total_genome_size)
        if perc_diference > 20:
            print(f"{fasta} exceeds 20% ({round(perc_diference)}%), deleting file ...")
            os.remove(fasta)

def main():
    assembly_dir = os.path.abspath(flags.directory)
    genome_size = open(flags.genome_size).read() if (lambda f: (f.close(), True))(open(flags.genome_size)) else None

    print(f"Cleaning up assembly fasta files that differ more than 20% from expected size")
    print(f"Target directory: {assembly_dir} ... \nexpecting a genome size of: {genome_size}")

    determine_size(assembly_dir, genome_size)

if __name__ == "__main__":
    main()
