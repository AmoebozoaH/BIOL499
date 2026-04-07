#!/usr/bin/env bash
set -euo pipefail

POLISH_DIR="/disk1/carol/Part2/flye_assembly/polished_medaka_polypolish_pypolca"
CHECKM_DIR="${POLISH_DIR}/polypolish_checkm_input"

mkdir -p "$CHECKM_DIR"

mapfile -d '' files < <(find "$POLISH_DIR" -type f -name "polypolished.fasta" -print0)

if [[ ${#files[@]} -eq 0 ]]; then
    echo "No polypolished.fasta files found under: $POLISH_DIR"
    exit 1
fi

for f in "${files[@]}"; do
    sample="$(basename "$(dirname "$f")")"
    ln -sfn "$(realpath "$f")" "$CHECKM_DIR/${sample}_polypolished.fasta"
    echo "linked: $CHECKM_DIR/${sample}_polypolished.fasta"
done

echo "Symlinks created in: $CHECKM_DIR"
ls -lh "$CHECKM_DIR"
