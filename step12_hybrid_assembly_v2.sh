#!/usr/bin/env bash

# if any commends/pipelines fails, stop
set -euo pipefail

# fucntion: polish nanopore assembly using short reading with Polypolish+pypolca
# requirement: already complete nanopore assembly with medaka, have illumina reads for short reads polishing.
# environment: activate environment contain Polypolish+pypolca, have bwa installed
# editted with gpt

# -------- paths --------
ASM_DIR="/disk1/carol/Part2/flye_assembly/polished_medaka/checkm_input"
READS_DIR="/disk1/carol/Part2/illumina_links/Trimmed_fastq"
OUT_DIR="/disk1/carol/Part2/flye_assembly/polished_medaka_polypolish_pypolca"

THREADS=16

mkdir -p "$OUT_DIR"

# -------- loop over all medaka assemblies --------
shopt -s nullglob
for asm in "$ASM_DIR"/*.medaka.fasta; do
  asm_base="$(basename "$asm")"
  sample="${asm_base%%_nanopore*}"   # e.g. i10_02_barcode11

  r1="$READS_DIR/${sample}_illumina_R1.trimmed.fastq.gz"
  r2="$READS_DIR/${sample}_illumina_R2.trimmed.fastq.gz"

  if [[ ! -f "$r1" || ! -f "$r2" ]]; then
    echo "[WARN] Missing reads for $sample"
    echo "       expected: $r1"
    echo "                 $r2"
    continue
  fi

  echo "[INFO] Processing $sample"
  sample_dir="$OUT_DIR/$sample"
  mkdir -p "$sample_dir"
  cd "$sample_dir"

  # ---------- Polypolish ----------
  ln -sfn "$asm" draft.fasta
  ln -sfn "$r1" reads_1.fastq.gz
  ln -sfn "$r2" reads_2.fastq.gz

  bwa index draft.fasta
  bwa mem -t "$THREADS" -a draft.fasta reads_1.fastq.gz > alignments_1.sam
  bwa mem -t "$THREADS" -a draft.fasta reads_2.fastq.gz > alignments_2.sam

  polypolish filter --in1 alignments_1.sam --in2 alignments_2.sam \
    --out1 filtered_1.sam --out2 filtered_2.sam

  polypolish polish draft.fasta filtered_1.sam filtered_2.sam > polypolished.fasta

  rm -f *.amb *.ann *.bwt *.pac *.sa alignments_*.sam filtered_*.sam

  # ---------- pypolca ----------
  # Output will go into sample_dir/pypolca_out (you can change)
  pypolca run -a polypolished.fasta \
    -1 reads_1.fastq.gz \
    -2 reads_2.fastq.gz \
    -t "$THREADS" \
    -o pypolca_out \
    --careful

  # Optional: collect final assembly into a single folder
  # (Adjust filename if pypolca outputs differently in your version)
  if [[ -f pypolca_out/assembly.fasta ]]; then
    cp -f pypolca_out/assembly.fasta "$OUT_DIR/${sample}.polypolish_pypolca.fasta"
  fi

done

echo "[DONE] Batch polishing finished. Results in: $OUT_DIR"
