#!/bin/bash
#SBATCH --time=5:00:00
#SBATCH --mem=10G
#SBATCH --mail-user=briallen.lobb@gmail.com
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --array=1-53

SAMP=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
echo "Starting task $SAMP"
module load StdEnv/2020 bracken/2.7
bracken -d ~/project/k2_pluspf_20250714/ -i Kraken_output_c0.6/${SAMP}.kreport -o ${SAMP}.bracken -l S