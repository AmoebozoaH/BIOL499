#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# maybe define resources, but I only know the name of the server. Add later if needed.
# Function: fastp pair end FASTQ files.
# file requirement: end with "R1_001.fastq.gz" and "R2_001.fastq.gz".
# I did not write anything for input error check, make sure files are there.

# set directories (maybe change to parameter later)
IN_DIR="/disk1/carol/Part2/illumina_links"
OUT_DIR="/disk1/carol/Part2/illumina_links/Trimmed_fastq"

# consulting document on https://github.com/OpenGene/fastp?tab=readme-ov-file#input-and-output
# make directory for OUT_DIR
cd "$IN_DIR"

echo "> make directory"
mkdir -p "$OUT_DIR"


# start looping
# for all R1 found in the same directory..
echo "> trimming fastq with fastp"
for R1 in *_R1.fastq.gz; do						# loop only R1s
	# obtain the match for R2
	R2="${R1/_R1.fastq.gz/_R2.fastq.gz}"			# for R1, substitute /x with /y to obtain R2

	# obtain identifier for naming later
	identifier="$(basename "$R1" | sed -E 's/.{12}$//')"		# remove last 16 characters "_R1.fastq.gz" from R1 name to obtain identifier

	# process individual pairs read through fastp
	echo "> processing $identifier for fastp"

	fastp \
		-i "$R1" \
		-I "$R2" \
		--out1 "$OUT_DIR/${identifier}_R1.trimmed.fastq.gz" \
    		--out2 "$OUT_DIR/${identifier}_R2.trimmed.fastq.gz" \
		--detect_adapter_for_pe \
		--report_title "$identifier" \
		-h "$OUT_DIR/${identifier}.fastp.html" \
		-j "$OUT_DIR/${identifier}.fastp.json"

		# annotation:
		# -i file -I file => set input as R1 and R2
		# --out1 file --out2 file => set output for R1.trim and R2.trim
		# --detect_adapter_for_pe => auto detect adapters, not default
		# --report_title "$x" => generate report, get to pick types
		# -h html, -j jason
		# auto quality filter, could use --n_base_limit, limit N base number
		# auto length filter, could use --length_required to set mini requirement

done

# output directory
echo "output directory: $OUT_DIR"
