#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# maybe define resources, but I only know the name of the server. Add later if needed.
# Function: perform assembly using pair end illumina fastq data
# file requirement: quality checked, trim, filtered, named as "*R1.fastq.gz" o>
# folder requirement: SPades generate a new folder in target directory, I prefer manua>

# set directory
IN_DIR="/disk1/carol/Part2/illumina_links/Trimmed_fastq"
OUT_DIR="/disk1/carol/Part2/illumina_spade_assembly1"

# consulting document on https://ablab.github.io/spades/

# create directory
mkdir -p "$OUT_DIR"
mkdir -p "$OUT_DIR"/Log

# start looping
# for a R1 in directory..
echo "start processing each file..."
for R1 in "$IN_DIR"/*_R1.trimmed.fastq.gz; do
        # obtain identifier by removing the last 20 characters
        identifier="$(basename "$R1" | sed -E 's/.{20}$//')"
        # Obtain file for R2 by replace "R1" to "R2"
        R2="${R1/_R1/_R2}"

        # test identifier/file name
        #echo "$identifier"
        #echo "$R2"

        # run spades on paired files
        # use identifier as the name of the folder
        # output error in log file
        spades.py \
                -1 "$R1" \
                -2 "$R2" \
                --isolate \
                -o "$OUT_DIR/$identifier" \
                > "$OUT_DIR/Log/${identifier}.out" \
                2> "$OUT_DIR/Log/${identifier}.err"
        echo "$identifier complete SPades Assemble"

done
