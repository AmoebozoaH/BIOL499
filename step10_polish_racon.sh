#!/usr/bin/env bash
set -euo pipefail

# note: remember to remove sam files after confirm all polished files are produced.



# initial setting
ASSEMBLY_DIR="/disk1/carol/Part2/flye_assembly/checkm_input"
READS_DIR="/disk1/carol/Part2/nanopore_raw"
OUT_MAIN="/disk1/carol/Part2/polisher_racon"
ITERATION="${1:-1}"
THREADS="${THREADS:-8}"

# make new directory
ITER_DIR="${OUT_MAIN}/polisher_racon_iteration${ITERATION}"
BAM_DIR="${ITER_DIR}/bam"
POL_DIR="${ITER_DIR}/polished_genome"
LOG_DIR="${ITER_DIR}/logs"

mkdir -p "$BAM_DIR" "$POL_DIR" "$LOG_DIR"

# Function to extract "barcodeXX" or "barcode12_33" from filename
extract_barcode() {
  local fn="$1"
  # returns first match like barcode11 or barcode12_33
  echo "$fn" | grep -oE 'barcode[0-9]+(_[0-9]+)?' | head -n 1 || true
}

# Loop over assemblies
shopt -s nullglob
assemblies=( "$ASSEMBLY_DIR"/*.fa "$ASSEMBLY_DIR"/*.fasta "$ASSEMBLY_DIR"/*.fna )
if [ ${#assemblies[@]} -eq 0 ]; then
  echo "ERROR: No assemblies found in $ASSEMBLY_DIR"
  exit 1
fi

# main function
for asm in "${assemblies[@]}"; do
  asm_base="$(basename "$asm")"
  barcode="$(extract_barcode "$asm_base")"

  if [ -z "$barcode" ]; then
    echo "SKIP: Could not find barcode in assembly name: $asm_base"
    continue
  fi

  # Find matching reads file(s) by barcode
  # Works for Batch*.barcode11.fastq.gz and Batch1_4.barcode12_33.fastq.gz, etc.
  mapfile -t candidates < <(ls -1 "$READS_DIR"/*."$barcode".fastq.gz 2>/dev/null || true)
  if [ ${#candidates[@]} -eq 0 ]; then
    # fallback: any file containing the barcode string
    mapfile -t candidates < <(ls -1 "$READS_DIR"/*"$barcode"*fastq.gz 2>/dev/null || true)
  fi

  if [ ${#candidates[@]} -eq 0 ]; then
    echo "SKIP: No reads found for $asm_base (barcode: $barcode)"
    continue
  fi

  # set files and outputs
  reads="${candidates[0]}"
  reads_base="$(basename "$reads")"

  sample="${asm_base%.*}"

  sam_out="${BAM_DIR}/${sample}.sam"
  bam_out="${BAM_DIR}/${sample}.bam"
  polished_out="${POL_DIR}/${sample}.racon_iter${ITERATION}.fasta"
  log_out="${LOG_DIR}/${sample}.log"

  ## do minimap2
  minimap2 \
	-t "$THREADS" \
	-ax map-ont "$asm" "$reads" > "$sam_out" 2> "$log_out"
  samtools sort -@ "$THREADS" -o "$bam_out" "$sam_out" >> "$log_out" 2>&1
  samtools index "$bam_out" >> "$log_out" 2>&1

  ## racon polish
  racon -t "$THREADS" "$reads" "$sam_out" "$asm" > "$polished_out" 2>> "$log_out"

  echo "DONE: $polished_out"

done

echo "All finished. Outputs in: $ITER_DIR"
