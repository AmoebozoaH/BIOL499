#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# fucntion: polish nanopore assembly using short reading with Polypolish+pypolca
# requirement: already complete nanopore assembly with medaka, have illumina reads for short reads polishing.
# environment: activate environment contain Polypolish+pypolca, have bwa installed

# Polypolish

bwa index draft.fasta
bwa mem -t 16 -a draft.fasta reads_1.fastq.gz > alignments_1.sam
bwa mem -t 16 -a draft.fasta reads_2.fastq.gz > alignments_2.sam
polypolish filter --in1 alignments_1.sam --in2 alignments_2.sam --out1 filtered_1.sam --out2 filtered_2.sam
polypolish polish draft.fasta filtered_1.sam filtered_2.sam > polished.fasta
rm *.amb *.ann *.bwt *.pac *.sa *.sam

# pypolca

pypolca run -a <genome> \
	-1 <R1 short reads file> \
	-2 <R2 short reads file> \
	-t <threads> \
	-o <output directory> \
	--careful

