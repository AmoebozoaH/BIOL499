#!/bin/bash
#SBATCH --time=10:00:00
#SBATCH --mem=200G
#SBATCH --cpus-per-task=20
#SBATCH --mail-user=briallen.lobb@gmail.com
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --array=1-53

SAMP=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
echo "Starting task $SAMP"
module load StdEnv/2020 gcc/9.3.0 kraken2/2.1.3
kraken2 --db ~/project/k2_pluspf_20250714/ --threads 20 --paired --gzip-compressed --output ${SAMP}.kraken --confidence 0.6 --report ${SAMP}.kreport ~/project/NaderProjects/Nader_Throat_PilotProject_2025_NEW/fastq_trim/${SAMP}_L005_R1_001_val_1.fq.gz ~/project/NaderProjects/Nader_Throat_PilotProject_2025_NEW/fastq_trim/${SAMP}_L005_R2_001_val_2.fq.gz
