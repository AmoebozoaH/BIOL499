import pandas as pd
from pathlib import Path

# ========= PATHS =========
MAP = Path("/disk1/carol/Part2/txt/final_illumina_nanopore_mapping.xlsx")

ILLUMINA_RAW = Path("/disk1/carol/Part2/illumina_raw")
NANOPORE_RAW = Path("/disk1/carol/Part2/nanopore_raw")

ILLUMINA_LINKS = Path("/disk1/carol/Part2/illumina_links")
NANOPORE_LINKS = Path("/disk1/carol/Part2/nanopore_links")
# =========================

# make directory
ILLUMINA_LINKS.mkdir(exist_ok=True)
NANOPORE_LINKS.mkdir(exist_ok=True)

# read in files
df = pd.read_excel(MAP)


for _, row in df.iterrows():
    idx = str(int(row["Illumina_index"]))

    # ---------- Illumina (R1 / R2) ----------
    for read in ("R1", "R2"):
        matches = list(ILLUMINA_RAW.glob(f"{idx}_*_{read}_001.fastq.gz"))
        if not matches:
            print(f"[WARN] illumina {read} not found for index {idx}")
            continue

        src = matches[0]
        dst = ILLUMINA_LINKS / row["illumina"].replace(
            ".fastq.gz", f"_{read}.fastq.gz"
        )

        if not dst.exists():
            dst.symlink_to(src)
        else:
            print(f"[SKIP] exists: {dst}")

    # ---------- Nanopore ----------
    src_np = NANOPORE_RAW / row["nanopore_filename"]
    if not src_np.exists():
        print(f"[WARN] nanopore missing: {src_np}")
        continue

    dst_np = NANOPORE_LINKS / row["nanopore"]

    if not dst_np.exists():
        dst_np.symlink_to(src_np)
    else:
        print(f"[SKIP] exists: {dst_np}")

print("Symlink creation complete.")
