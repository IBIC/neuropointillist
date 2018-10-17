
#' Write an output makefile
#'
#' Generate a makefile for running a specific analysis
#' @param prefix Prefix for output, to be prepended to outputs
#' @param resultnames List of names for the expected outputs
#' @param modelfile Name of the R model file that contains the processVoxel command
#' @param designmat Design matrix
#' @param makefile Name of makefile
#' @param localscript Name of script to execute makefile locally
#' @export
npointWriteMakefile <- function(prefix, resultnames, modelfile, designmat, makefile, localscript) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    # the names of the outputfiles that are created
    outputfiles <- paste(paste("%", resultnames, ".nii.gz",sep=""),collapse=" ")

    # the first outputfile
    firstoutputfile <- paste(resultnames[1], ".nii.gz",sep="")

    fileConn <- file(localscript)
    writeLines(c("make -j 4\n"), fileConn)
    Sys.chmod(localscript, "775")
    close(fileConn)

    fileConn <- file(makefile)
    alltarget <- "all: $(outputs) "
    allrules <- c()
    mostlyclean <- "mostlyclean:\n\trm -f "

    clean <- "clean: mostlyclean\n\trm -f *.rds $(masks) npoint.e* npoint.o*"     
    
    for (i in resultnames) {
        alltarget <- c(alltarget, paste("$(PREFIX)", i, ".nii.gz" , sep=""))
        allrules <- c(allrules, paste("$(PREFIX)", i, ".nii.gz: ", "$(masks:%.nii.gz=%", i, ".nii.gz)\n\tnpointmerge $@ $^\n",sep=""))
        mostlyclean <- c(mostlyclean, paste("$(masks:%.nii.gz=%", i, ".nii.gz) ",sep=""))
    }

    writeLines(c("#Set the number of threads to be 1 to avoid overloading single cores\n",
                 "export OMP_NUM_THREADS=1",
                 paste("PREFIX=", prefix,sep=""),
                 "#All output files are made at the same time so here we only need to list the first.\n",
                 paste("OUTPUT=",firstoutputfile,sep=""),
                 paste("MODEL=",modelfile,sep=""),
                 paste("DESIGNMAT=",designmat,sep=""),
                 "# You can change or remove the time command. This is to gauge memory allocation and time to allow for completion on clusters.\n",
                 "TIME=/usr/bin/time --verbose",
                 "\n",
                 "masks:= $(wildcard $(PREFIX)????.nii.gz)",
                 "outputs:=$(masks:%.nii.gz=%$(OUTPUT))",
                 "\n",
                 paste(alltarget,collapse=" "),
                 "\n",
                 "# Because this is a pattern rule, npointrun will be launched only once for all targets.\n",
                 paste(outputfiles, ": %.nii.gz\n\t$(TIME) npointrun -m $< --model $(MODEL) -d $(DESIGNMAT)"),
                 "\n",
                 allrules,
                 "\n",
                 paste(mostlyclean,collapse=""),
                 clean),
               fileConn)
    close(fileConn)

}
