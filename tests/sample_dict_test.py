import pathlib
import argparse
from juno_library import Pipeline

def test_pipeline(input_dir, sequencing_tech):
    pipeline = Pipeline(
        pipeline_name="test_pipeline",
        pipeline_version="1.0",
        input_type="fastq",
        argv=[
            "--input", str(input_dir),
            "--output", "output",
            "--sequencing-tech", sequencing_tech
        ]
    )
    pipeline.setup()
    return pipeline.sample_dict

def test_illumina():
    illumina_input_dir = pathlib.Path("/mnt/scratch_dir/singhsp/ONT_development/sample_data/listeria_test")
    illumina_sample_dict = test_pipeline(illumina_input_dir, "illumina")
    print("Illumina Sample Dict:")
    print(illumina_sample_dict)

def test_nanopore():
    nanopore_input_dir = pathlib.Path("/mnt/scratch_dir/singhsp/ONT_development/nanopore_input")
    nanopore_sample_dict = test_pipeline(nanopore_input_dir, "nanopore")
    print("Nanopore Sample Dict:")
    print(nanopore_sample_dict)

def main():
    parser = argparse.ArgumentParser(description="Test sample dictionary building for different sequencing technologies.")
    parser.add_argument('--tech', choices=['illumina', 'nanopore', 'both'], required=True, help="Specify the sequencing technology to test.")
    args = parser.parse_args()

    if args.tech == 'illumina':
        print("Running Illumina Test:")
        test_illumina()
    elif args.tech == 'nanopore':
        print("Running Nanopore Test:")
        test_nanopore()
    elif args.tech == 'both':
        print("Running Illumina Test:")
        test_illumina()
        print("\nRunning Nanopore Test:")
        test_nanopore()

if __name__ == "__main__":
    main()