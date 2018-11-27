#' Write an output PBS submit script
#'
#' Generate an PBS submit script for the given workflow
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
#' npointWritePBSsubmitscript()
npointWritePBSsubmitscript <- function(prefix, resultnames, modelfile, designmat,masterscript,jobscript,njobs) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    # the name of one of the outputfiles that is created
    outputfile <- paste(resultnames[1], ".nii.gz",sep="")
    fileConnMaster <- file(masterscript)
    fileConnJob <- file(jobscript)
    writeLines(c("#!/bin/bash",
                 "# This script will submit jobs to PBS. You can also run this job locally by typing make, if appropriate.",
                 paste("qsub",  basename(jobscript), sep=" "),
                 "echo When you get mail from PBS that your job has completed, cd to this directory and type:",
                 "echo make"),
               fileConnMaster)

    user <- Sys.getenv("USER")
    writeLines(c("#!/bin/sh",
                 "### PBS preamble",
                 "#LOOK AT THESE AND EDIT TO OVERRIDE FOR YOUR JOB",         
                 "#PBS -N npoint",
                 paste("#PBS -M ", user, "@umich.edu", sep=""),
                 "#PBS -m ae",
                 "# Change this to be the name of your allocation",
                 "#PBS -A support_flux",
                 "#PBS -q flux",
                 "#PBS -j oe",
                 "#PBS -l procs=8,pmem=2gb",
                 "#PBS -l walltime=24:00:00",
                 "#PBS -V",
                 paste("#PBS -t 1-", njobs, "%8",sep=""),
                "export OMP_NUM_THREADS=1",                 
                 paste("MODEL=",modelfile,sep=""),
                 paste("DESIGNMAT=",designmat,sep=""),
                 "num=$(printf \"%04d\" $PBS_ARRAYID)",
                 paste("cd ", getwd(), "/", dirname(jobscript), sep=""),
                 paste("npointrun -m ", basename(prefix), "${num}.nii.gz --model ${MODEL} -d ${DESIGNMAT}",sep=""),
                 "\n"),
               fileConnJob)
    Sys.chmod(masterscript, "775")
}

