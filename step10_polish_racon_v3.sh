#!/usr/bin/env bash
set -euo pipefail

# note: remove SAM/BAM files later if you no longer need them
# iterative racon polishing for all assemblies in ASSEMBLY_DIR

ASSEMBLY_DIR="/disk1/carol/Part2/flye_assembly/checkm_input"
READS_DIR="/disk1/carol/Part2/nanopore_qc_all/filtlong"
OUT_MAIN="/disk1/carol/Part2/flye_assembly/new_polish_ones/polisher_racon_new"

THREADS="${THREADS:-16}"
ITER_START="${1:-1}"
N_ITERS="${2:-4}"

extract_barcode() {
    local fn="$1"
    # matches barcode11 or barcode12_33
    echo "$fn" | grep -oE 'barcode[0-9]+(_[0-9]+)?' | head -n 1 || true
}

shopt -s nullglob

assemblies=(
    "$ASSEMBLY_DIR"/*.fa
    "$ASSEMBLY_DIR"/*.fasta
    "$ASSEMBLY_DIR"/*.fna
)

echo "Assembly dir: $ASSEMBLY_DIR"
echo "Reads dir:    $READS_DIR"
echo "Output dir:   $OUT_MAIN"
echo "Threads:      $THREADS"
echo "Iter start:   $ITER_START"
echo "N iters:      $N_ITERS"
echo "Assemblies found: ${#assemblies[@]}"
echo

if [ ${#assemblies[@]} -eq 0 ]; then
    echo "ERROR: No assemblies found in $ASSEMBLY_DIR"
    exit 1
fi

for asm in "${assemblies[@]}"; do
    asm_base="$(basename "$asm")"
    barcode="$(extract_barcode "$asm_base")"

    echo "=================================================="
    echo "Processing assembly: $asm_base"
    echo "Extracted barcode:  ${barcode:-<none>}"

    if [ -z "$barcode" ]; then
        echo "SKIP: Could not find barcode in assembly name: $asm_base"
        echo
        continue
    fi

    candidates=( "$READS_DIR"/*"$barcode"*.fastq.gz )

    if [ ${#candidates[@]} -eq 0 ]; then
        echo "SKIP: No reads found for $asm_base (barcode: $barcode)"
        echo
        continue
    fi

    if [ ${#candidates[@]} -gt 1 ]; then
        echo "WARNING: Multiple read files matched for $barcode"
        printf '  %s\n' "${candidates[@]}"
        echo "Using first match."
    fi

    reads="${candidates[0]}"
    sample="${asm_base%%.*}"
    asm_current="$asm"

    echo "Using reads: $(basename "$reads")"
    echo "Sample name: $sample"
    echo

    for ((it=ITER_START; it<ITER_START+N_ITERS; it++)); do
        ITER_DIR="${OUT_MAIN}/polisher_racon_iteration${it}"
        BAM_DIR="${ITER_DIR}/bam"
        POL_DIR="${ITER_DIR}/polished_genome"
        LOG_DIR="${ITER_DIR}/logs"

        mkdir -p "$BAM_DIR" "$POL_DIR" "$LOG_DIR"

        sam_out="${BAM_DIR}/${sample}.iter${it}.sam"
        bam_out="${BAM_DIR}/${sample}.iter${it}.bam"
        log_out="${LOG_DIR}/${sample}.iter${it}.log"
        polished_out="${POL_DIR}/${sample}.racon_iter${it}.fasta"

        echo "  --- Iteration $it ---"
        echo "  Assembly input: $(basename "$asm_current")"
        echo "  Log file: $log_out"

        minimap2 -t "$THREADS" -ax map-ont "$asm_current" "$reads" > "$sam_out" 2> "$log_out"
        samtools sort -@ "$THREADS" -o "$bam_out" "$sam_out" >> "$log_out" 2>&1
        samtools index "$bam_out" >> "$log_out" 2>&1

        racon -t "$THREADS" "$reads" "$sam_out" "$asm_current" > "$polished_out" 2>> "$log_out"

        echo "  DONE iter $it: $polished_out"
        echo

        asm_current="$polished_out"
    done
done

echo "All finished. Outputs in: $OUT_MAIN"
