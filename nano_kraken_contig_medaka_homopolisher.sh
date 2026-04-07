#!/bin/bash
#SBATCH --time=10:00:00
#SBATCH --mem=200G
#SBATCH --cpus-per-task=20
#SBATCH --mail-user=z392huan@uwaterloo.ca
#SBATCH --output=/home/z392huan/scratch/Part2/nanopore_homopolisher/log/kraken_nano_medaka_homo_%A_%a.out
#SBATCH --error=/home/z392huan/scratch/Part2/nanopore_homopolisher/log/kraken_nano_medaka_homo_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --array=1-42

# Script for kraken contig
# Function: kraken classification at contig level
# kraken manual: https://ccb.jhu.edu/software/kraken/MANUAL.html
# requirement: preconstruct sample.txt file using ls *.fasta | sed 's/\.fasta$//' > nanopore_sample.txt


#mkdir -p /home/z392huan/scratch/kraken_contig_result/
mkdir -p /home/z392huan/scratch/Part2/nanopore_medaka_homopolisher/kraken_contig_result/
DIR="/home/z392huan/scratch/Part2/nanopore_medaka_homopolisher/kraken_contig_result/"

SAMP=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /home/z392huan/scratch/Part2/nanopore_medaka_homopolisher/nanopore_medaka_homo_sample.txt)
echo "Starting task $SAMP"
module load StdEnv/2020 gcc/9.3.0 kraken2/2.1.3
kraken2 --db /home/z392huan/projects/def-acdoxey/k2_pluspf_20250714 \
        --threads 20 \
	--confidence 0.1 \
	--unclassified-out ${DIR}/${SAMP}.unclassified.fasta \
	--classified-out ${DIR}/${SAMP}.classified.fasta \
	--output ${DIR}/${SAMP}.kraken \
	--report ${DIR}/${SAMP}.report \
	/home/z392huan/scratch/Part2/nanopore_medaka_homopolisher/${SAMP}.fasta
