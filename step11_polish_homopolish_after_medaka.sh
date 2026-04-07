#!/usr/bin/env bash
set -euo pipefail

# === EDIT THESE ===
WORKDIR="/disk1/carol/Part2/flye_assembly/polished_medaka"
THREADS=16
OUTDIR="/disk1/carol/Part2/flye_assembly/polished_medaka_homopolish"
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

   # rename homopolish output fasta
   old_fa="${SAMPLE_OUT}/${SAMPLE}_homopolished.fasta"
   new_fa="${SAMPLE_OUT}/${SAMPLE}.medaka_homopolish.fasta"   # <-- change this name

   if [[ -f "$old_fa" ]]; then
   	cp "$old_fa" "$new_fa"
   else
   	echo "WARNING: expected output not found: $old_fa"
   	ls -lh "$SAMPLE_OUT"
   fi

echo "All done. Outputs (best-effort): ${OUTDIR}/*/*.medaka_homopolish.fasta"

done
