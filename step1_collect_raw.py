import pandas as pd
from pathlib import Path
import shutil

MAP = Path("/disk1/carol/Part2/txt/illumina_nanopore_mapping.xlsx")

# set directory
ILLUMINA_SRC = Path("/disk1/carol/WGS_TAP")
NANOPORE_SRC = Path("/disk1/carol/Nanopore")

ILLUMINA_DST = Path("/disk1/carol/Part2/illumina_raw")
NANOPORE_DST = Path("/disk1/carol/Part2/nanopore_raw")

# make sure the directory exist and aviablible
ILLUMINA_DST.mkdir(parents=True, exist_ok=True)
NANOPORE_DST.mkdir(parents=True, exist_ok=True)

# Read in my mapping file
df = pd.read_excel(MAP)

# process by looping
for _, row in df.iterrows():
    idx = str(int(row["Illumina_index"]))

    # illumina R1 / R2
    for read in ["R1", "R2"]:
        src = next(ILLUMINA_SRC.glob(f"{idx}_*_{read}_001.fastq.gz"), None)
        if src:
            shutil.copy2(src, ILLUMINA_DST / src.name)
        else:
            print(f"[WARN] missing illumina {read} for index {idx}")

    # nanopore
    np_src = NANOPORE_SRC / row["nanopore_filename"]
    if np_src.exists():
        shutil.copy2(np_src, NANOPORE_DST / np_src.name)
    else:
        print(f"[WARN] missing nanopore file {np_src}")
