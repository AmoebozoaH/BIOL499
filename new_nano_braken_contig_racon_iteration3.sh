#!/bin/bash
#SBATCH --time=5:00:00
#SBATCH --mem=10G
#SBATCH --mail-user=z392huan@uwaterloo.ca
#SBATCH --output=/home/z392huan/script/log/contig_braken_nano_racon3_%A_%a.out
#SBATCH --error=/home/z392huan/script/log/contig_braken_nano_racon3_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --array=1-41

# Script obtained from briallen
# function: abundance estimation?
# documentation: https://github.com/jenniferlu717/Bracken

mkdir -p /home/z392huan/scratch/Part2/nanopore_racon/polisher_racon_iteration3_new/braken_contig_result

SAMP=$(sed -n "${SLURM_ARRAY_TASK_ID}p"  /home/z392huan/scratch/Part2/nanopore_racon/polisher_racon_iteration3_new/nanopore_racon3_sample.txt)
echo "Starting task $SAMP"
module load StdEnv/2020 bracken/2.7
bracken -d /home/z392huan/projects/def-acdoxey/k2_pluspf_20250714/ \
	-i /home/z392huan/scratch/Part2/nanopore_racon/polisher_racon_iteration3_new/kraken_contig_result/${SAMP}.report \
	-o /home/z392huan/scratch/Part2/nanopore_racon/polisher_racon_iteration3_new/braken_contig_result/${SAMP}.bracken \
	-l S
