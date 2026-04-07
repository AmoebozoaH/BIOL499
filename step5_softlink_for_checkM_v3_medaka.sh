#!/usr/bin/env bash
set -euo pipefail

# a version just for medaka

cd /disk1/carol/Part2/flye_assembly/polished_medaka
mkdir -p checkm_input

for f in *.medaka.fasta; do
    ln -sfn "$(realpath "$f")" checkm_input/"$f"
done


