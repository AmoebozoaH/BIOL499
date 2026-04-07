#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# reference documentation: https://github.com/Ecogenomics/CheckM/wiki/Quick-Start#typical-workflow
# function: evaluate genome completeness and contamination
# note: activate conda environment before working

# for racon only
INDIR="/disk1/carol/Part2/flye_assembly/polished_racon_medaka/"
mkdir -p "$INDIR/checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/checkm_input" --output-directory "$INDIR/checkm_result"
