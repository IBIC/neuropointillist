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
#' @param pbsPre The name of a preamble file for PBS - this should exist 
#' @export
#' @examples
#' 
#' npointWritePBSsubmitscript()
npointWritePBSsubmitscript <- function(prefix, resultnames, modelfile, designmat,masterscript,jobscript,njobs,pbsPre) {
    # the directory where we are putting stuff
    dir <- dirname(jobscript)
    # the name of one of the outputfiles that is created
    outputfile <- paste(resultnames[1], ".nii.gz",sep="")
    if (!(is.null(pbsPre))) {
        # make a copy of the preamble for reference and to master script
        preamblecopy <- paste(dir, basename(pbsPre),sep="/")
        file.copy(pbsPre, preamblecopy)
        file.copy(pbsPre, jobscript)        
    }
    fileConnMaster <- file(masterscript)

    writeLines(c("#!/bin/bash",
                 "# This script will submit jobs to PBS. You can also run this job locally by typing make, if appropriate.",
                 paste("qsub",  basename(jobscript), sep=" "),
                 "echo When you get mail from PBS that your job has completed, cd to this directory and type:",
                 "echo make"),
               fileConnMaster)

    # if we have not specified a preamble, write one
    if (is.null(pbsPre)) {
        user <- Sys.getenv("USER")
        cat("#!/bin/sh\n",
            "### PBS preamble\n",
            "#LOOK AT THESE AND EDIT TO OVERRIDE FOR YOUR JOB\n",         
            "#PBS -N npoint\n",
            paste("#PBS -M ", user, "@umich.edu\n", sep=""),
            "#PBS -m ae\n",
            "# Change this to be the name of your allocation\n",
            "#PBS -A support_flux\n",
            "#PBS -q flux\n",
            "#PBS -j oe\n",
            "# Modify this to match your specific resource needs\n",
            "#PBS -l nodes=1:ppn=1,pmem=2gb\n",
            "#PBS -l walltime=24:00:00\n",
            "#PBS -V\n",
            paste("#PBS -t 1-", njobs, "%8\n",sep=""), "\n",
            sep="",
            file=jobscript)
    }
    #Preamble or not, write the main work part
    cat("export OMP_NUM_THREADS=1\n",                 
        paste("MODEL=",modelfile,"\n", sep=""),
        paste("DESIGNMAT=",designmat,"\n", sep=""),
        "num=$(printf \"%04d\" $PBS_ARRAYID)\n",
        paste("cd ", getwd(), "/", dirname(jobscript), "\n", sep=""),
        paste("npointrun -m ", basename(prefix), "${num}.nii.gz --model ${MODEL} -d ${DESIGNMAT}\n",sep=""),
        "\n",
        sep="",
        file=jobscript, append=TRUE)
    Sys.chmod(masterscript, "775")
}

