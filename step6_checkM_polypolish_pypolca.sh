#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# reference documentation: https://github.com/Ecogenomics/CheckM/wiki/Quick-Start#typical-workflow
# function: evaluate genome completeness and contamination
# note: activate conda environment before working

# for polupolisher after medaka
INDIR="/disk1/carol/Part2/flye_assembly/polished_medaka_polypolish_pypolca/"
mkdir -p "$INDIR/polypolish_checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/polypolish_checkm_input" --output-directory "$INDIR/polypolish_checkm_result"

# for pypolca after medaka+polypolisher
INDIR="/disk1/carol/Part2/flye_assembly/polished_medaka_polypolish_pypolca/"
mkdir -p "$INDIR/pypolca_checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/pypolca_checkm_input" --output-directory "$INDIR/pypolca_checkm_result"
