"""
Atlas Assembler
Authors: Fabian Landman, Sohana Singh, Roxanne Wolthuis
Organization: Rijksinstituut voor Volksgezondheid en Milieu (RIVM)
Department: Infektieziekteonderzoek, Diagnostiek en Laboratorium
            Surveillance (IDS), Bacteriologie (BPD)     
Date: 31-03-2025   
"""

from pathlib import Path
import pathlib
import yaml
import argparse
import sys
from dataclasses import dataclass, field
from juno_library import Pipeline
from typing import Optional
from version import __package_name__, __version__, __description__

def main() -> None:
    atlas_assembler = AtlasAssembler()
    atlas_assembler.run()

@dataclass
class AtlasAssembler(Pipeline):
    pipeline_name: str = __package_name__
    pipeline_version: str = __version__
    input_type: str = "fastq"

    def _add_args_to_parser(self) -> None:
        super()._add_args_to_parser()

        self.parser.description = "Atlas Assembler pipeline for assembly of sigle read ONT sequencing data"
        
        self.add_argument(
            "-d",
            "--db-dir",
            type=Path,
            metavar="DIR",
            default="/mnt/db/juno/kraken2_db",
            help="Relative or absolute path to the Kraken2 database. Default: /mnt/db/juno/kraken2_db.",
        )
        self.add_argument(
            "-hc",
            "--headcrop",
            type=int,
            metavar="INT",
            default=0,
            help="Trim N nucleotodes from the start of a read",
		)
        self.add_argument(
            "-tc",
            "--tailcrop",
            type=int,
            metavar="INT",
            default=0,
            help="Trim N nucleotides from N nucleotides from the end of a read",
		)
        self.add_argument(
            "-len",
            "--length",
            type=int,
            metavar="INT",
            default=1,
            help="Trim N nucleotides from N nucleotides from the end of a read",
		)
        self.add_argument(
            "-kp",
            "--keep-percentage",
            type=float,
            metavar="FLOAT",
            default=0.8,
            help="Percentage of reads that should be kept after trimming. Default: 0.8",
        )
        self.add_argument(
            "-mpt",
            "--mean-quality-threshold",
            type=int,
            metavar="INT",
            default=28,
            help="Phred score to be used as threshold for cleaning (filtering) fastq files.",
        )
        self.add_argument(
            "-ws",
            "--window-size",
            type=int,
            metavar="INT",
            default=5,
            help="Window size to use for cleaning (filtering) fastq files.",
        )
        self.add_argument(
            "-ml",
            "--minimum-length",
            type=int,
            metavar="INT",
            default=50,
            dest="min_read_length",
            help="Minimum length for fastq reads to be kept after trimming.",
        )
        self.add_argument(
            "-qu",
            "--quality",
            type=int,
            metavar="INT",  
            default=20,
        )
    def _parse_args(self) -> argparse.Namespace:
        args = super()._parse_args()

        # Optional arguments are loaded into self here
        self.db_dir: Path = args.db_dir.resolve()
        self.headcrop: int = args.headcrop
        self.tailcrop: int = args.tailcrop
        self.length: int = args.length
        self.keep_percentage: float = args.keep_percentage
        self.mean_quality_threshold: int = args.mean_quality_threshold
        self.window_size: int = args.window_size
        self.min_read_length: int = args.min_read_length
        self.quality: int = args.quality

        return args
    
    # Extra class methods for this pipeline can be defined here
    def example_class_method(self):
        print(f"example option is set to {self.example}")

    def setup(self) -> None:
        super().setup()
        self.snakemake_args["use_conda"] = True
        if self.snakemake_args["use_singularity"]:
            self.snakemake_args["singularity_args"] = " ".join(
                [
                    self.snakemake_args["singularity_args"]
                ] # paths that singularity should be able to read from can be bound by adding to the above list
            )

        # Extra class methods for this pipeline can be invoked here
        # if self.example:
        #     self.example_class_method()

        with open(
            Path(__file__).parent.joinpath("config/pipeline_parameters.yaml")
        ) as f:
            parameters_dict = yaml.safe_load(f)
        self.snakemake_config.update(parameters_dict)

        self.user_parameters = {
            "input_dir": str(self.input_dir),
            "output_dir": str(self.output_dir),
            "exclusion_file": str(self.exclusion_file),
            # "example": str(self.example), # other user parameters can be included in user_parameters.yaml here
            "db_dir": str(self.db_dir),
            "headcrop": str(self.headcrop),
            "tailcrop": str(self.tailcrop),
            "length": str(self.length),
            "keep_percentage": str(self.keep_percentage),
            "mean_quality_threshold": str(self.mean_quality_threshold),
            "window_size": str(self.window_size),
            "min_read_length": str(self.min_read_length),
            "quality": str(self.quality),
        }


if __name__ == "__main__":
    main()
