#' Write an output Slurm submit script
#'
#' Generate an Slurm submit script for the given workflow
#' @param prefix Prefix for output, to be prepended to outputs
#' @param resultnames List of names for the expected outputs
#' @param modelfile Name of the model file that contains the processVoxel command
#' @param designmat Design matrix
#' @param masterscript Name of the master submit script
#' @param jobscript Name of the job submission script
#' @param njobs Number of jobs to submit
#' @export
#' @examples
#' 
#' npointWriteSlurmsubmitscript()
npointWriteSlurmsubmitscript <- function(prefix, resultnames, modelfile, designmat,masterscript,jobscript,njobs) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    # the name of one of the outputfiles that is created
    outputfile <- paste(resultnames[1], ".nii.gz",sep="")
    fileConnMaster <- file(masterscript)
    fileConnJob <- file(jobscript)
    writeLines(c("#!/bin/bash",
                 "# This script will submit jobs to Slurm. You can also run this job locally by typing make.",
                 paste("sbatch --array=1-", njobs, " ",  basename(jobscript), sep=""),
                 "echo When you get mail from slurm that your job has completed, cd to this directory and type:",
                 "echo make"),
               fileConnMaster)


    writeLines(c("#!/bin/bash",
                 "\n",
                 "#Slurm submission options",
                 "#LOOK AT THESE AND EDIT TO OVERRIDE FOR YOUR JOB",         
                 "#SBATCH -p ncf_holy",
                 "#SBATCH --mem 4000",
                 "#SBATCH --time 0-6:00",
                 "#SBATCH --mail-type=END",
                 "#SBATCH -o npoint_%A_%a.out",
                "#SBATCH -o npoint_%A_%a.err",                                                   "export OMP_NUM_THREADS=1",
                 paste("MODEL=",modelfile,sep=""),
                 paste("DESIGNMAT=",designmat,sep=""),
                 "num=$(printf \"%04d\" $SLURM_ARRAY_TASK_ID)",
                 paste("npointrun -m ", basename(prefix), "${num}.nii.gz --model ${MODEL} -d ${DESIGNMAT}",sep=""),
                 "\n"),
               fileConnJob)
    Sys.chmod(masterscript, "775")
}

