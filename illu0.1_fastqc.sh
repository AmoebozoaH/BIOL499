#!/bin/bash

# Exit immediately if a command fails
set -euo pipefail

# Make an output directory for FastQC reports
INDIR="/disk1/carol/Part2/illumina_links"
OUTDIR="fastqc_pretrim_reports"
mkdir -p "$INDIR/$OUTDIR"

echo "Running FastQC on all FASTQ files..."
for file in "$INDIR"/*fastq.gz
do
    echo "Processing: $file"
    fastqc "$file" -o "$INDIR/$OUTDIR"
done

echo "All FastQC runs finished."
echo "Reports saved in: $OUTDIR"


