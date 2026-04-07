#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# reference documentation: https://github.com/Ecogenomics/CheckM/wiki/Quick-Start#typical-workflow
# function: evaluate genome completeness and contamination
# note: activate conda environment checkm2 before working

# for SPades
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input /disk1/carol/WGS_TAP/checkm_input --output-directory /disk1/carol/WGS_TAP/checkm_output

# for Unicycler
#mkdir -p /disk1/carol/WGS_TAP/checkm_output_uni
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input /disk1/carol/WGS_TAP/checkm_input_uni --output-directory /disk1/carol/WGS_TAP/checkm_output_uni

# for Spades (newest)
INDIR="/disk1/carol/Part2/illumina_spade_assembly1/"
mkdir -p "$INDIR/checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/checkm_input" --output-directory "$INDIR/checkm_result"


# check before use
