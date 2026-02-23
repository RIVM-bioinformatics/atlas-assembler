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

def get_suppported_checkm_genera() -> list[str]:
    with open(
        Path(__file__).parent.joinpath("files", "accepted_genera_checkm.txt"), mode="r"
    ) as f:
        return [g.strip().lower() for g in f.readlines()]


@dataclass
class AtlasAssembler(Pipeline):
    pipeline_name: str = __package_name__
    pipeline_version: str = __version__
    input_type: str = "fastq"
    supported_genera: list[str] = field(default_factory=get_suppported_checkm_genera)

    def _add_args_to_parser(self) -> None:
        super()._add_args_to_parser()
        supported_genera = self.supported_genera

        class HelpGeneraAction(argparse.BooleanOptionalAction):
            def __call__(self, *args, **kwargs) -> None:  # type: ignore
                print("\n".join([f"The accepted genera are:"] + supported_genera))
                exit(0)



        self.parser.description = "Atlas Assembler pipeline for assembly of sigle read ONT sequencing data"
        self.add_argument(
            "--help-genera",
            action=HelpGeneraAction,
            help="Prints the genera accepted by this pipeline.",
        )
        self.add_argument(
            "-g",
            "--genus",
            type=str.lower,
            choices=self.supported_genera,
            default=None,
            metavar="GENUS",
            help="Genus of the samples to be analyzed. If metadata is given, the genus in the metadata will overwrite the one given through this option.",
        )
        self.add_argument(
            "-m",
            "--metadata",
            type=Path,
            default=None,
            metavar="FILE",
            dest="metadata_file",
            help="Relative or absolute path to a .csv file. If provided, it must contain at least one column with the 'Sample' name (name of the file but removing _R1.fastq.gz) and a column called 'Genus' (mind the capital in the first letter). The genus provided will be used to choose the reference genome to analyze de QC of the de novo assembly.",
        )
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
            default=80,
            help="Trim N nucleotodes from the start of a read",
		)
        self.add_argument(
            "-tc",
            "--tailcrop",
            type=int,
            metavar="INT",
            default=80,
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
            type=int,
            metavar="FLOAT",
            default=80,
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
            default=4,
            help="Window size to use for cleaning (filtering) fastq files.",
        )
        self.add_argument(
            "-ml",
            "--minimum-length",
            type=int,
            metavar="INT",
            default=1000,
            dest="min_read_length",
            help="Minimum length for fastq reads to be kept after trimming.",
        )
        self.add_argument(
            "-qu",
            "--quality",
            type=int,
            metavar="INT",  
            default=10,
        )
        self.add_argument(
        "--medaka_rounds",
        metavar="Val",
        help="Number of medaka rounds for polishing in case of supplying medaka flag, default 1",
        type=str,
        nargs='?',
        const='1',
        default='1',
        required=False,
    )
        self.add_argument(
            "--medaka_model",
            metavar="Name",
            help="Medaka model to use when polishing, will also be supplied through the start_longread_assembly.sh",
            type=str,
            required=False,
        )
        self.add_argument(
        "--auto_exe",
        metavar="Name",
        help="Path to Autocycler executable",
        default='Unknown',
        type=str,
        required=False,
    )
        self.add_argument(
            "-sdb",
            "--skani-gtdb-db-dir",
            type=Path,
            metavar="DIR",
            default="/mnt/db/juno/skani/gtdb_skani_database_ani-version-r226",
            help="Relative or absolute path to the Skani GTDB database. Default: '%(default)s'.",
    )
        self.add_argument(
            "-sm",
            "--skani-max-no-hits",
            type=int,
            metavar="INT",
            default=1,
            dest="skani_max_no_hits",
            help="Maximum number of hits to report for each contig in the Skani step. Default is 1, change value for debugging or development only.",
    )
    def _parse_args(self) -> argparse.Namespace:
        args = super()._parse_args()

        # Optional arguments are loaded into self here
        self.db_dir: Path = args.db_dir.resolve()
        self.metadata_file: Optional[Path] = args.metadata_file
        self.genus: Optional[str] = args.genus
        self.headcrop: int = args.headcrop
        self.tailcrop: int = args.tailcrop
        self.length: int = args.length
        self.keep_percentage: float = args.keep_percentage
        self.mean_quality_threshold: int = args.mean_quality_threshold
        self.window_size: int = args.window_size
        self.min_read_length: int = args.min_read_length
        self.quality: int = args.quality
        self.medaka_rounds: int = args.medaka_rounds
        self.medaka_model: str = args.medaka_model
        self.auto_exe: str = args.auto_exe
        self.skani_max_no_hits = args.skani_max_no_hits
        self.skani_gtdb_db_dir = args.skani_gtdb_db_dir.resolve()
        self.time_limit: int = args.time_limit
        return args
    
    # Extra class methods for this pipeline can be defined here
    def example_class_method(self):
        print(f"example option is set to {self.example}")

    def update_sample_dict_with_metadata(self) -> None:
        self.get_metadata_from_csv_file(
            filepath=self.metadata_file, expected_colnames=["sample", "genus"]
        )
        for sample, properties in self.sample_dict.items():
            try:
                properties["genus"] = (
                    self.juno_metadata[sample]["genus"].strip().lower()
                )
            except (KeyError, TypeError, AttributeError):
                properties["genus"] = self.genus  # type: ignore

    def setup(self) -> None:
        super().setup()
        self.snakemake_args["use_conda"] = True
        self.snakemake_args["latency_wait"] = 120
        if self.snakemake_args["use_singularity"]:
            self.snakemake_args["singularity_args"] = " ".join(
                [
                    self.snakemake_args["singularity_args"]
                ] # paths that singularity should be able to read from can be bound by adding to the above list
            )
        if self.time_limit < 300:
            self.time_limit = 300
        self.update_sample_dict_with_metadata()

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
            "genus": self.genus,
            "headcrop": str(self.headcrop),
            "tailcrop": str(self.tailcrop),
            "length": str(self.length),
            "keep_percentage": str(self.keep_percentage),
            "mean_quality_threshold": str(self.mean_quality_threshold),
            "window_size": str(self.window_size),
            "min_read_length": str(self.min_read_length),
            "quality": str(self.quality),
            "medaka_rounds": str(self.medaka_rounds),
            "medaka_model": str(self.medaka_model),
            "auto_exe": str(self.auto_exe),
            "skani_gtdb_db_dir": str(self.skani_gtdb_db_dir),
            "skani_max_no_hits": int(self.skani_max_no_hits),
            "time-limit": str(self.time_limit),
        }


if __name__ == "__main__":
    main()
