#!/usr/bin/env bash
set -euo pipefail

# after racon is completed
# picked racon1 result, seems to be the best
# activate medaka conda environment to run the softwares
#redo, picked racon version 3

# set to directory of racon output genomes (fasta)
WORKDIR="/disk1/carol/Part2/flye_assembly/new_polish_ones/polisher_racon_new/polisher_racon_iteration3/polished_genome"
# set to directory with filtered reads
READSDIR="/disk1/carol/Part2/nanopore_qc_all/filtlong"
# set output directory
OUTDIR="/disk1/carol/Part2/flye_assembly/new_polish_ones/polished_racon_medaka"
THREADS=16
MODEL="r1041_e82_400bps_hac_v4.2.0"

mkdir -p "$OUTDIR"
cd "$WORKDIR"


### note for regex!
for ASM in *.fasta; do
   	SAMPLE="$(basename "$ASM" .fasta)"
	BASE_SAMPLE="${SAMPLE%%.racon_iter*}"
	READS="${READSDIR}/${BASE_SAMPLE}.min1000.kp95.fastq.gz"
    	SAMPLE_OUT="${OUTDIR}/${SAMPLE}"

    if [[ ! -f "$READS" ]]; then
        echo "[WARN] Reads not found for $SAMPLE"
        echo "       expected: $READS"
        continue
    fi

    mkdir -p "$SAMPLE_OUT"

    echo "=== [MEDAKA] $SAMPLE ==="
    echo "assembly: $ASM"
    echo "reads:    $READS"

    medaka_consensus \
        -i "$READS" \
        -d "$ASM" \
        -o "$SAMPLE_OUT" \
        -t "$THREADS" \
        -m "$MODEL"

    if [[ -f "$SAMPLE_OUT/consensus.fasta" ]]; then
        cp "$SAMPLE_OUT/consensus.fasta" "$OUTDIR/${SAMPLE}.racon.medaka.fasta"
    fi
done

echo "All done. Outputs: $OUTDIR/*.racon.medaka.fasta"
