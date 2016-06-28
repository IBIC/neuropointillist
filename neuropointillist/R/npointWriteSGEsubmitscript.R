#' Write an output SGE submit script
#'
#' Generate an SGE submit script for the given workflow
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
#' npointWriteSGEsubmitscript()
npointWriteSGEsubmitscript <- function(prefix, resultnames, modelfile, designmat,masterscript,jobscript,njobs) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    # the name of one of the outputfiles that is created
    outputfile <- paste(resultnames[1], ".nii.gz",sep="")
    fileConnMaster <- file(masterscript)
    fileConnJob <- file(jobscript)
    writeLines(c("#!/bin/bash",
                 "# This script will submit jobs to SGE. You can also run this job by typing make.",
                 paste("qsub -S /bin/bash -sync y", basename(jobscript)),
                 "make"),
               fileConnMaster)


    writeLines(c("#!/bin/bash",
                 "\n",
                 "#SGE submission options",
                 "#$ -cwd",
                 "#$ -V",
                 paste("#$ -t 1-", njobs, sep=""),
                 "#$ -N npoint",
                 "export OMP_NUM_THREADS=1",
                 paste("MODEL=",modelfile,sep=""),
                 paste("DESIGNMAT=",designmat,sep=""),
                 "num=$(printf \"%04d\" $SGE_TASK_ID)",
                 paste("npointrun -m ", basename(prefix), "${num}.nii.gz --model ${MODEL} -d ${DESIGNMAT}",sep=""),
                 "\n"),
               fileConnJob)
    Sys.chmod(masterscript, "775")
}

