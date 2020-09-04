#!/bin/bash

#To run this for 1000 permutations execute:
# `sbatch --array=1-1000 permutations.slurm.bash`

#Slurm submission options
#LOOK AT THESE AND EDIT TO OVERRIDE FOR YOUR JOB
#!/bin/bash
#Slurm submission options
#SBATCH -o npointperm_%A_%a.out
#SBATCH --mail-type=END

export OMP_NUM_THREADS=1

#You shouldn't need to edit below this
num=$(printf "%04d" $SLURM_ARRAY_TASK_ID)
dashm="n.p.0001.nii.gz"
model="$(pwd -P)/nlmemodel.permute.R"
permfile="finger-Z.${num}permute.nii.gz"
design="n.p.designmat.rds"

echo running: srun -c 1 /usr/bin/time --verbose npointrun -m ${dashm} --model ${model} --permutationfile ${permfile} -d "${design}"

srun -c 1 /usr/bin/time --verbose npointrun -m ${dashm} --model ${model} --permutationfile ${permfile} -d ${design}
