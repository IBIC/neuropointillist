#' Write an output nextflow file for permutation testing
#'
#' Generate a nextflow workflow for running a specific analysis
#' @param prefix Prefix for output, to be prepended to outputs
#' @param resultnames Names of results from processvoxel. You can return multiple permutation statistics, with names, and they will be used to write multiple permutation files
#' @param modelfile Name of the R model file that contains the processVoxel command
#' @param designmat Design matrix
#' @param nextflow Name of nextflow workflow
#' @param npermutations Number of permutations to run#' 
#' @export
npointWriteNextflowPermute <- function(prefix, resultnames, modelfile, designmat, nextflow,  npermutations) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    # the names of the outputfiles that are created
    outputsection <- paste("\tfile \"${prefix}0001", resultnames, ".${x}.nii.gz\"\n", sep="")

    # the name of one output file. Any one will do because they will all be created at each permutation
    
    permuteoutputfile <- paste(resultnames[1], ".${x}.nii.gz", sep="")

    # write configuration file
    
    configConn <- file(paste(dirname(nextflow), "/nextflow.config",sep=""))
    writeLines(c("process {",
                 "withName:npointrun {",
                 "container='FILLTHISIN'",
                 "executor=\"awsbatch\"",
                 paste("queue=\"npoint_batch_queue_", Sys.getenv("LOGNAME"), "\"", sep=""),
                 "}",
                 "}",
                 "docker {",
                 "enabled = true",
                 "}"),configConn)
    
    close(configConn)

    fileConn <- file(nextflow)


    clean <- "clean:\n\trm -f *.rds $(mask) npoint.e* npoint.o*"     
    
    
    writeLines(c("#!/usr/bin/env nextflow/n",
                 paste("prefix='", prefix,"'",sep=""),
                 paste("npermute=",npermutations,sep=""),
                 paste("model='",modelfile,"'",sep=""),
                 paste("designmat='",designmat,"'",sep=""),
                 "//Lines that begin with two slashes are comments.",
                 "//If you have any other files that you want to use with your code, define them here.",
                 "//For example:",
                 "//extra='/path/to/file/my/R/code/needs.rds'",
                 "\n",
                 "maskFile = Channel.fromPath(\"${prefix}????.nii.gz\")",
                 "rdsFile =  Channel.fromPath(\"${prefix}????.rds\")",
                 "modelFile =  Channel.fromPath(\"${model}\")",
                 "designmatFile =  Channel.fromPath(\"${designmat}\")",
                 "\n",
                 "//If you have any other files that you want to use with your code, create a channel for them here",
                 "//For example:",
                 "//extraFile = Channel.fromPath(\"${extra}\")",
                 "process npointrun {\n  publishDir = \".\"\n\ninput:",
                 "\teach x from 1..npermute",
                 "\tfile mask from maskFile",
                 "\tfile rds from rdsFile",
                 "\tfile model from modelFile",
                 "\tfile designmat from designmatFile",
                 "//And also list any other files here. For example:",
                 "//\tfile extradat from extraFile",
                 "\n",
                 "output:",
                 outputsection,
                 "\"\"\"",
                 paste("npointrun -m ${mask} --model ${model} --permutationfile ", permuteoutputfile, " -d ${designmat}", sep=""),
                 "\"\"\"",

                 "}"),
               fileConn)
    close(fileConn)

}
