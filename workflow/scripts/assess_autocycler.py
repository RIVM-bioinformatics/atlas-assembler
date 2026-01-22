import glob, os, argparse, shutil, sys
from Bio import SeqIO
from Bio import SeqUtils
from pathlib import Path

# Check if the autocycler consensus fasta is good enough to finalize the pipeline. It checks if there are no more than 50 contigs and L90 is equal or less than 2.
# If it's not then it will delete all subset assemblies that do not contain a largest contig with the size of at least 60% of expected genome size.
# python bin/clean_assembly_dir.py -d /path/to/all_assemblies/ -g genome_size.txt
# -d /data/BioGrid/landmanf/data/longread_validation/run_2b_PAU55953/autocycler/PR0007_barcode78_11060659/assemblies -g /data/BioGrid/landmanf/data/longread_validation/run_2b_PAU55953/autocycler/PR0007_barcode78_11060659/genome-size.txt

EXIT_SUCCESS = 0
EXIT_REPEAT_AUTOCYCLER = 42
EXIT_NO_FASTA_LEFT = 4

arg = argparse.ArgumentParser()

arg.add_argument(
    "-i",
    "--input",
    metavar="Name",
    help="Input path tp autocycler consensus assembly fasta",
    type=str,
    required=True,
)

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

arg.add_argument(
    "-p",
    "--percentage",
    metavar="Val",
    help="Percentage of genome expected as largest contig size",
    type=int,
    required=True,
    )
flags = arg.parse_args()

def percentage_difference(a, b):
    return abs(a / max(a, b)) * 100

def count_contigs(fasta_file):
    with open(fasta_file) as fasta:
        count = sum(1 for _ in SeqIO.parse(fasta, "fasta"))
    return count

def remove_fasta(all_fasta_list, to_keep_list):
    to_remove = [fasta for fasta in all_fasta_list if fasta not in to_keep_list]
    for fasta in to_remove:
        file_path = Path(fasta)
        if file_path.exists():  # Check if file exists before deleting
            if file_path.is_file():
                file_path.unlink()
                print(f"Deleted: {fasta}")
            else:
                print(f"Skipped: {fasta} is not a file")
        else:
            print(f"File not found, skipping: {fasta}")

def assess_autocycler_consensus(fastafile, ctg_lengths, expected_genome_size):
    count_output = count_contigs(fastafile)
    calc_L90_output = calculate_L90(ctg_lengths, expected_genome_size)
    if count_output > 50 and calc_L90_output >= 2:
        print(f"Woah more than 50 contigs and L90 more or equal to 2")
        print(f"Contig count: {count_output}, L90: {calc_L90_output}")
        return True
    else:
        print(f"Contig count: {count_output}, L90: {calc_L90_output}")
        return False

def calculate_L90(contig_lengths, expected_genome_size):
    contig_lengths = sorted(contig_lengths, reverse=True)  # Sort longest to shortest
    target_size = 0.9 * expected_genome_size  # 90% of genome size
    cumulative_size = 0
    count = 0

    for length in contig_lengths:
        cumulative_size += length
        count += 1
        if cumulative_size >= target_size:
            return count  # Number of contigs needed for 90% coverage
    return 1 # None  # If genome size is too big for given contigs

def assess_subset_fasta(assdir, expected_genome_size, perc):
    total_above_threshold = 0
    fasta_all_list = []
    fasta_keep_list = []
    print(f"Aiming to keep input fasta with a percentage above: {perc}%")
    for fasta in glob.glob(f"{assdir}/*.fasta"):
        fasta_all_list.append(fasta)
        for record in SeqIO.parse(fasta, "fasta"):
            perc_diference = percentage_difference(len(record.seq), expected_genome_size)
            if perc_diference > perc:
                fasta_keep_list.append(fasta)
                total_above_threshold += 1
                percentage_keep = round(len(record.seq) / expected_genome_size * 100, 2)
                print(f"Keeping this file: {fasta} length of my ctg: {len(record.seq)} length of my genome size: {expected_genome_size} ({percentage_keep}%)")
                break # if any of the contig sizes is above threshold we're keeping that file
    print(f"Total file(s) still above threshold: {total_above_threshold}")
    return fasta_all_list, fasta_keep_list, total_above_threshold


def main():
    assembly_dir = os.path.abspath(flags.directory)
    genome_size = open(flags.genome_size).read() if (lambda f: (f.close(), True))(open(flags.genome_size)) else None
    contig_lengths = [len(record.seq) for record in SeqIO.parse(flags.input, "fasta")]

    print(f"Target directory: {assembly_dir} ... \nexpecting a genome size of: {genome_size}")
    print(Path(flags.input).parent)
    repeat_autocycler = assess_autocycler_consensus(flags.input, contig_lengths, int(genome_size))
    if repeat_autocycler:
        print(f"Assessing if able to repeat this analysis ...")
        assess_output = assess_subset_fasta(assembly_dir, int(genome_size), flags.percentage)
        if assess_output[2] == 0:
            print(f"No fasta files above percentage threshold unable to continue Autocycler")
            sys.exit(EXIT_NO_FASTA_LEFT)
        remove_fasta(assess_output[0], assess_output[1])
        print(f"{assess_output[2]} fasta file(s) left to try again using Autocycler")
        sys.exit(EXIT_REPEAT_AUTOCYCLER)
    else:
        print(f"It's looking good I can create my final output to signal pipeline has completed")
        sys.exit(EXIT_SUCCESS)
    # Only do this part when the check on autocycler consensus fasta has failed, e.g. >100 ctgs and small sized. And generate some exit code to check for in Snakemake to then start again from a checkpoint.


if __name__ == "__main__":
    main()
