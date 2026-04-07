#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/disk1/carol/Part2/flye_assembly/polished_medaka_polypolish_pypolca"
CHECKM_INPUT_DIR="${BASE_DIR}/pypolca_checkm_input"

mkdir -p "$CHECKM_INPUT_DIR"

find "$BASE_DIR" -type f -path "*/pypolca_out/pypolca_corrected.fasta" -print0 |
while IFS= read -r -d '' f; do
    sample="$(basename "$(dirname "$(dirname "$f")")")"
    ln -sfn "$(realpath "$f")" "$CHECKM_INPUT_DIR/${sample}_pypolca_corrected.fasta"
    echo "linked: $CHECKM_INPUT_DIR/${sample}_pypolca_corrected.fasta"
done

echo "Symlinks created in: $CHECKM_INPUT_DIR"
ls -lh "$CHECKM_INPUT_DIR"
