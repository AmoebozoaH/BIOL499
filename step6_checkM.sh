#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# reference documentation: https://github.com/Ecogenomics/CheckM/wiki/Quick-Start#typical-workflow
# function: evaluate genome completeness and contamination
# note: activate conda environment before working

# for SPades
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input /disk1/carol/WGS_TAP/checkm_input --output-directory /disk1/carol/WGS_TAP/checkm_output

# for Unicycler
#mkdir -p /disk1/carol/WGS_TAP/checkm_output_uni
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input /disk1/carol/WGS_TAP/checkm_input_uni --output-directory /disk1/carol/WGS_TAP/checkm_output_uni

# for flye nanopore (newest)
#INDIR="/disk1/carol/Part2/flye_assembly"
#mkdir -p "$INDIR/checkm_result"
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/checkm_input" --output-directory "$INDIR/checkm_result"


# for flye nanopore (newest)
#INDIR="/disk1/carol/Part2/flye_assembly/polished_homopolish"
#mkdir -p "$INDIR/checkm_result"
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/checkm_input" --output-directory "$INDIR/checkm_result"

# for flye nanopore (newest)
#INDIR="/disk1/carol/Part2/flye_assembly/polished_medaka"
#mkdir -p "$INDIR/checkm_result"
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/checkm_input" --output-directory "$INDIR/checkm_result"

# for flye nanopore (newest)
#INDIR="/disk1/carol/Part2/flye_assembly/polisher_racon/polisher_racon_iteration1/polished_genome"
#mkdir -p "$INDIR/checkm_result"
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR" --output-directory "$INDIR/checkm_result"


# for flye nanopore homo+medaka
#INDIR="/disk1/carol/Part2/flye_assembly/polished_medaka_homopolish"
#mkdir -p "$INDIR/checkm_result"
#/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR/checkm_input" --output-directory "$INDIR/checkm_result"

# for nanopore_after_kraken_filter
INDIR="/disk1/carol/Part2/kraken_filtered_assembly/nanopore"
mkdir -p "$INDIR/checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR" --output-directory "$INDIR/checkm_result"

# for illumina_after_kraken_filter
INDIR="/disk1/carol/Part2/kraken_filtered_assembly/illumina"
mkdir -p "$INDIR/checkm_result"
/home/carol/checkm2/bin/checkm2 predict --threads 8 -x fasta --input "$INDIR" --output-directory "$INDIR/checkm_result"
