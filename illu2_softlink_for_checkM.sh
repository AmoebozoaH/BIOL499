#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# fucntion: create softlink for all contig files, get them into same folder. Need to precreate folder.


cd /disk1/carol/Part2/illumina_spade_assembly1
mkdir -p checkm_input

for d in *_barcode*; do
	if [ -f "$d/contigs.fasta" ]; then
		ln -s "$PWD/$d/contigs.fasta" "./checkm_input/${d}.fasta"
	fi
done



# double check before use
