#!/usr/bin/env bash
set -euo pipefail

# function run assembly on all nanopore data

# ===== EDIT THESE =====
IN_DIR="/disk1/carol/Part2/nanopore_qc_all/filtlong"
OUT_DIR="/disk1/carol/Part2/flye_assembly"
THREADS=16
GENOME_SIZE="5m"   # adjust if needed, or comment out
# ======================

mkdir -p "$OUT_DIR"

# get a list of file names
shopt -s nullglob
files=("$IN_DIR"/*.fastq.gz)


for f in "${files[@]}"; do
	# obtain name for each sample
	base="$(basename "$f" .fastq.gz)"
	# set output directory for each sample
	sample_out="${OUT_DIR}/${base}"

	# just in case if I have run this multiple times...
	if [[ -d "$sample_out" ]]; then
		echo "[SKIP] Assembly already exists for $base"
		continue
	fi

	echo "=============================="
	echo "[INFO] Assembling: $base"
	echo "[INFO] Input: $f"

	# run flye for the $base assembly
	flye \
		--nano-raw "$f" \
		--out-dir "$sample_out" \
		--threads "$THREADS" \
		--genome-size "$GENOME_SIZE" \
		> "${sample_out}.flye.out" \
		2> "${sample_out}.flye.err"

done

echo "[DONE] All Flye assemblies finished."
