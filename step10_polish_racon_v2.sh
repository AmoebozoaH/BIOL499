#!/usr/bin/env bash
set -euo pipefail

# note: remember to remove sam files after confirm all polished files are produced.
# version 2 allow iterative racon running
# modifed with ChatGPT


# initial setting
ASSEMBLY_DIR="/disk1/carol/Part2/flye_assembly/checkm_input"
READS_DIR="/disk1/carol/Part2/nanopore_qc_all/filtlong"
OUT_MAIN="/disk1/carol/Part2/flye_assembly/new_polish_ones/polisher_racon_new"
THREADS="${THREADS:-16}"
ITER_START="${1:-1}"
N_ITERS="${2:-4}"

# Function to extract "barcodeXX" or "barcode12_33" from filename
extract_barcode() {
  local fn="$1"
  # returns first match like barcode11 or barcode12_33
  echo "$fn" | grep -oE 'barcode[0-9]+(_[0-9]+)?' | head -n 1 || true
}

shopt -s nullglob
# Loop over assemblies
assemblies=( "$ASSEMBLY_DIR"/*.fa "$ASSEMBLY_DIR"/*.fasta "$ASSEMBLY_DIR"/*.fna )
if [ ${#assemblies[@]} -eq 0 ]; then
  echo "ERROR: No assemblies found in $ASSEMBLY_DIR"
  exit 1
fi

# main function: sequential racon polishing
for asm in "${assemblies[@]}"; do
  asm_base="$(basename "$asm")"
  barcode="$(extract_barcode "$asm_base")"

  if [ -z "$barcode" ]; then
    echo "SKIP: Could not find barcode in assembly name: $asm_base"
    continue
  fi

  # Find matching reads file(s) by barcode
  mapfile -t candidates < <(ls -1 "$READS_DIR"/*."$barcode".fastq.gz 2>/dev/null || true)
  if [ ${#candidates[@]} -eq 0 ]; then
    # fallback: any file containing the barcode string
    mapfile -t candidates < <(ls -1 "$READS_DIR"/*"$barcode"*fastq.gz 2>/dev/null || true)
  fi

  if [ ${#candidates[@]} -eq 0 ]; then
    echo "SKIP: No reads found for $asm_base (barcode: $barcode)"
    continue
  fi

  reads="${candidates[0]}"
  sample="${asm_base%%.*}"

  asm_current="$asm"

  for ((it=ITER_START; it<ITER_START+N_ITERS; it++)); do
    # per-iteration directories
    ITER_DIR="${OUT_MAIN}/polisher_racon_iteration${it}"
    BAM_DIR="${ITER_DIR}/bam"
    POL_DIR="${ITER_DIR}/polished_genome"
    LOG_DIR="${ITER_DIR}/logs"
    mkdir -p "$BAM_DIR" "$POL_DIR" "$LOG_DIR"

    # per-iteration files
    sam_out="${BAM_DIR}/${sample}.iter${it}.sam"
    bam_out="${BAM_DIR}/${sample}.iter${it}.bam"
    log_out="${LOG_DIR}/${sample}.iter${it}.log"
    polished_out="${POL_DIR}/${sample}.racon_iter${it}.fasta"

    # minimap2 mapping
    minimap2 -t "$THREADS" -ax map-ont "$asm_current" "$reads" > "$sam_out" 2> "$log_out"
    samtools sort -@ "$THREADS" -o "$bam_out" "$sam_out" >> "$log_out" 2>&1
    samtools index "$bam_out" >> "$log_out" 2>&1

    # racon polish
    racon -t "$THREADS" "$reads" "$sam_out" "$asm_current" > "$polished_out" 2>> "$log_out"

    echo "DONE iter $it: $polished_out"

    # feed output into next iteration
    asm_current="$polished_out"
  done
done

echo "All finished. Outputs in: $OUT_MAIN"
