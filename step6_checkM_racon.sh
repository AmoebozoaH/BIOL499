#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# reference documentation: https://github.com/Ecogenomics/CheckM/wiki/Quick-Start#typical-workflow
# function: evaluate genome completeness and contamination
# note: activate conda environment before working

# for racon only
INDIR="/disk1/carol/Part2/flye_assembly/new_polish_ones/polisher_racon_new/polisher_racon_iteration1"
mkdir -p "$INDIR/checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/polished_genome" --output-directory "$INDIR/checkm_result"

# for racon only
INDIR="/disk1/carol/Part2/flye_assembly/new_polish_ones/polisher_racon_new/polisher_racon_iteration2"
mkdir -p "$INDIR/checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/polished_genome" --output-directory "$INDIR/checkm_result"

# for racon only
INDIR="/disk1/carol/Part2/flye_assembly/new_polish_ones/polisher_racon_new/polisher_racon_iteration3"
mkdir -p "$INDIR/checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/polished_genome" --output-directory "$INDIR/checkm_result"

# for racon only
INDIR="/disk1/carol/Part2/flye_assembly/new_polish_ones/polisher_racon_new/polisher_racon_iteration4"
mkdir -p "$INDIR/checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/polished_genome" --output-directory "$INDIR/checkm_result"
