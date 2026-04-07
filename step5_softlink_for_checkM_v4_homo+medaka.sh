#!/usr/bin/env bash
set -euo pipefail

# a version just for homopolisher+medaka

cd /disk1/carol/Part2/flye_assembly/polished_medaka_homopolish
mkdir -p checkm_input

# symlink all fasta files inside *.medaka/ directories into checkm_input/
find . -type f -name "*.fasta" -path "./*.medaka/*" -print0 |
  while IFS= read -r -d '' f; do
    bn="$(basename "$f")"
    ln -sfn "$(realpath "$f")" "checkm_input/$bn"
  done
