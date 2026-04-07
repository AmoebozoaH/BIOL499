#!/usr/bin/env bash
set -euo pipefail

base="/disk1/carol/Part2/flye_assembly/polished_homopolish"
out="checkm_input"

cd "$base"
mkdir -p "$out"

for d in *kp95; do
  [[ -d "$d" ]] || continue

  # collect candidate fasta files in this dir (prefer homopolished)
  mapfile -t cands < <(
    find "$d" -maxdepth 1 -type f \( \
      -iname "*homopolished*.fasta" -o -iname "*homopolished*.fa" -o -iname "*homopolished*.fna" -o \
      -iname "*.fasta" -o -iname "*.fa" -o -iname "*.fna" \
    \) | sort
  )

  if (( ${#cands[@]} == 0 )); then
    echo "WARNING: no fasta found in $d" >&2
    continue
  fi

  if (( ${#cands[@]} > 1 )); then
    echo "NOTE: multiple fasta files in $d; using: ${cands[0]}" >&2
  fi

  fasta="${cands[0]}"
  link="${out}/${d}.fasta"   # CheckM just needs unique filenames

  # -s = symlink, -f = overwrite existing, -n = treat existing link as file
  ln -sfn "$(realpath "$fasta")" "$link"
done
