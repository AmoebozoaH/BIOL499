#!/usr/bin/env bash
set -euo pipefail


# after racon is completed
# picked racon1 result, seems to be the best



# === EDIT THESE ===
WORKDIR="/disk1/carol/Part2/flye_assembly/polisher_racon/polisher_racon_iteration1/polished_genome"
READSDIR="/disk1/carol/Part2/nanopore_qc_all/filtlong/"   # filtered reads
OUTDIR="/disk1/carol/Part2/flye_assembly/polished_racon_medaka"
THREADS=16
MODEL="r1041_e82_400bps_hac_v4.2.0"
# for Flowcell: R10.4.1, Kit: E8.2, Speed: 400bps, Basecaller: HAC v4.2.0
# ================

mkdir -p "${OUTDIR}"

cd "${WORKDIR}"

for ASM in *.fasta; do
  SAMPLE="$(basename "${ASM}" .fasta)"
  SAMPLE_OUT="${OUTDIR}/${SAMPLE}"
  mkdir -p "${SAMPLE_OUT}"

  echo "=== [MEDAKA] ${SAMPLE} ==="

  # Medaka wants an assembly + reads
  # Output consensus typically ends up in ${SAMPLE_OUT}/consensus.fasta
  medaka_consensus \
    -i "${READSDIR}/${SAMPLE}.fastq.gz" \
    -d "${ASM}" \
    -o "${SAMPLE_OUT}" \
    -t "${THREADS}" \
    -m "${MODEL}"

  # Copy/rename final fasta to a consistent filename
  if [[ -f "${SAMPLE_OUT}/consensus.fasta" ]]; then
    cp "${SAMPLE_OUT}/consensus.fasta" "${OUTDIR}/${SAMPLE}.racon.medaka.fasta"
  fi
done

echo "All done. Outputs: ${OUTDIR}/*.racon.medaka.fasta"

