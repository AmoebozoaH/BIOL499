#!/usr/bin/env bash
set -euo pipefail

############################
# EDIT THESE PATHS
############################

# not in use I believe
ASSEMBLY_DIR="/disk1/carol/Part2/flye_assembly/checkm_input"
READS_DIR="/disk1/carol/Part2/nanopore_links"

THREADS=32

OUTDIR="/disk1/carol/Part2/flye_assembly/bam_alignments_minimap2"
mkdir -p "${OUTDIR}"

############################

cd "${ASSEMBLY_DIR}"

for ASM in *.fasta; do

    PREFIX=$(basename "${ASM}" .min1000.kp95.fasta)

    READ="${READS_DIR}/${PREFIX}.fastq.gz"

    if [[ ! -f "${READ}" ]]; then
        echo "issing FASTQ for ${PREFIX}"
        continue
    fi

    echo "=================================="
    echo "Aligning ${PREFIX}"
    echo "=================================="

    BAM="${OUTDIR}/${PREFIX}.bam"

    minimap2 \
        -ax map-ont \
        -t ${THREADS} \
        "${ASM}" "${READ}" | \
    samtools sort \
        -@ ${THREADS} \
        -o "${BAM}"

    samtools index "${BAM}"

done

echo "✅ All alignments completed."
