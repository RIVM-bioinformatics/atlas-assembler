import sys
import os

fields = [
    "Mean read length",
    "Mean read quality",
    "Median read length",
    "Median read quality",
    "Number of reads",
    "Read length N50",
    "STDEV read length",
    "Total bases"
]

def parse_stats(stats_file):
    values = {}
    with open(stats_file) as f:
        for line in f:
            for field in fields:
                if line.startswith(field):
                    value = line.split(":", 1)[1].strip().replace(",", "")
                    values[field] = value
    return values

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python parse_nanostats.py <NanoStats1.txt> [NanoStats2.txt ...] <output.tsv>")
        sys.exit(1)

    *input_files, output_file = sys.argv[1:]

    with open(output_file, "w") as out:
        out.write("sample\t" + "\t".join(fields) + "\n")
        for stats_file in input_files:
            # Extract sample name from path (assumes .../nanoplot/{sample}/NanoStats.txt)
            sample = os.path.basename(os.path.dirname(stats_file))
            values = parse_stats(stats_file)
            out.write(sample + "\t" + "\t".join(values.get(f, "") for f in fields) + "\n")