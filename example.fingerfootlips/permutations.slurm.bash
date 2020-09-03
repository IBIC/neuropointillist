#!/bin/bash

#To run this for 1000 permutations execute:
# `sbatch --array=1-1000 permutations.slurm.bash`

#Slurm submission options
#LOOK AT THESE AND EDIT TO OVERRIDE FOR YOUR JOB
#SBATCH --mem 3G
#SBATCH -p ncf
#SBATCH --cpus-per-task 1
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time 0-24:00
#SBATCH -o npointperm_%A_%a.out
#SBATCH --mail-type=END
#SBATCH --account=mclaughlin_lab

module load gcc/7.1.0-fasrc01
module load R/3.5.1-fasrc01

cp ~/.R/Makevars.gcc ~/.R/Makevars

export R_LIBS_USER=/ncf/mclaughlin/users/jflournoy/R_3.5.1_GCC:$R_LIBS_USER
export OMP_NUM_THREADS=1

#You shouldn't need to edit below this
num=$(printf "%04d" $SLURM_ARRAY_TASK_ID)
dashm="n.p.0001.nii.gz"
model="$(pwd -P)/nlmemodel.permute.R"
permfile="finger-Z.${num}permute.nii.gz"
design="n.p.designmat.rds"

echo running: srun -c 1 /usr/bin/time --verbose npointrun -m "${dashm}" --model "${model}" --permutationfile "${permfile}" -d "${design}"

srun -c 1 /usr/bin/time --verbose npointrun -m "${dashm}" --model "${model}" --permutationfile "${permfile}" -d "${design}"
