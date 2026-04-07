#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# fucntion: create softlink for all contig files, get them into same folder. Need to precreate folder.


cd /disk1/carol/Part2/flye_assembly/polished_homopolish
mkdir -p checkm_input

for d in *kp95; do
	# make sure its a directory
	[ -d "$d" ] || continue
	# if target file exist, make softlink
	# edit file name extract and file name links
	if [ -f "$d/*.fasta" ]; then
		ln -s "$PWD/$d/*.fasta" "./checkm_input/${d}.homopolisher.fasta"
	else
		echo "WARNING: $d/assembly.fasta not found" >&2
	fi
done



# double check before use
