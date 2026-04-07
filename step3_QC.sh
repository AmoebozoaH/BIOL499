#!/usr/bin/env bash
set -euo pipefail

# function: does nanoStat, Nanoplot, and filter using filtlong, then check data again using NanoStat and Nanoplot
# requires: all raw data under same directory

# edit directory is needed
IN_DIR="/disk1/carol/Part2/nanopore_links"   # or /disk1/carol/Part2/nanopore_raw
OUT_DIR="/disk1/carol/Part2/nanopore_qc_all"

# according to guideline (file in zotero)
MINLEN=1000
KEEP=95
THREADS=4   # used by NanoPlot; filtlong is mostly single-threaded
# ======================

# all output are placed under OUT_DIR
RAW_STAT_DIR="${OUT_DIR}/nanostat_raw"
RAW_PLOT_DIR="${OUT_DIR}/nanoplot_raw"
FILT_DIR="${OUT_DIR}/filtlong"
FILT_STAT_DIR="${OUT_DIR}/nanostat_filt"
FILT_PLOT_DIR="${OUT_DIR}/nanoplot_filt"
LOG_DIR="${OUT_DIR}/logs"

mkdir -p "$RAW_STAT_DIR" "$RAW_PLOT_DIR" "$FILT_DIR" "$FILT_STAT_DIR" "$FILT_PLOT_DIR" "$LOG_DIR"

# obtain file list
shopt -s nullglob
files=("$IN_DIR"/*.fastq.gz)

if [[ ${#files[@]} -eq 0 ]]; then
	echo "[ERROR] No .fastq.gz files found in $IN_DIR"
	exit 1
fi

# for all files obtained form previous step, do
for f in "${files[@]}"; do

	base="$(basename "$f" .fastq.gz)"
	echo "=============================="
	echo "[INFO] Sample: $base"
	echo "[INFO] Input : $f"

	# ---------- 1) NanoStat (raw) ----------
	NanoStat --fastq "$f" > "${RAW_STAT_DIR}/${base}.nanostat.txt" 2> "${LOG_DIR}/${base}.nanostat_raw.log"

	# ---------- 2) NanoPlot (raw) ----------
	NanoPlot --fastq "$f" \
		--outdir "${RAW_PLOT_DIR}/${base}" \
		--threads "$THREADS" \
		> "${LOG_DIR}/${base}.nanoplot_raw.out" 2> "${LOG_DIR}/${base}.nanoplot_raw.err"

	# ---------- 3) Filtlong ----------
	filt_out="${FILT_DIR}/${base}.min${MINLEN}.kp${KEEP}.fastq.gz"
		( filtlong --min_length "$MINLEN" --keep_percent "$KEEP" "$f" | gzip -c > "$filt_out" ) 2> "${LOG_DIR}/${base}.filtlong.log"

	# ---------- 4) NanoStat (filtered) ----------
	NanoStat --fastq "$filt_out" > "${FILT_STAT_DIR}/${base}.nanostat.txt" 2> "${LOG_DIR}/${base}.nanostat_filt.log"

	# ---------- 5) NanoPlot (filtered) ----------
	NanoPlot --fastq "$filt_out" \
		--outdir "${FILT_PLOT_DIR}/${base}" \
		--threads "$THREADS" \
		> "${LOG_DIR}/${base}.nanoplot_filt.out" 2> "${LOG_DIR}/${base}.nanoplot_filt.err"

done

echo "=============================="
echo "[DONE] All QC complete."
echo "[DONE] Outputs in: $OUT_DIR"
