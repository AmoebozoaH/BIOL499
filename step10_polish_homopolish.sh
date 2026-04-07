#!/usr/bin/env bash
set -euo pipefail

# === EDIT THESE ===
WORKDIR="/disk1/carol/Part2/flye_assembly/checkm_input"
THREADS=16
OUTDIR="/disk1/carol/Part2/flye_assembly/polished_homopolish"
# the model is base on whats used for basecalling and the mahcine used for nanopore
MODEL="/disk1/carol/homopolish/R10.3.pkl"

GENUS="Streptococcus"
TYPE="/disk1/carol/homopolish/bacteria.msh"
mkdir -p "${OUTDIR}"

cd "${WORKDIR}"

for ASM in *.fasta; do
  SAMPLE="$(basename "${ASM}" .fasta)"
  SAMPLE_OUT="${OUTDIR}/${SAMPLE}"
  mkdir -p "${SAMPLE_OUT}"

  echo "=== [HOMOPOLISH] ${SAMPLE} ==="

  # NOTE: you may need to adjust arguments based on your homopolish version.
  # Common style: homopolish <assembly> <outdir> [options]
  python3 /disk1/carol/homopolish/homopolish.py polish \
    	-a "${ASM}" \
	-m "$MODEL" \
    	-s "$TYPE"  \
    	-o "${SAMPLE_OUT}" \
    	-t "${THREADS}" || {
      echo "Homopolish failed for ${SAMPLE}. Check your homopolish command/args."
      continue
    }

echo "All done. Outputs (best-effort): ${OUTDIR}/*.homopolish.fasta"


done
