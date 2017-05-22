
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
    # the name of one of the outputfiles that is created
    outputfile <- paste(resultnames[1], ".nii.gz",sep="")

    fileConn <- file(localscript)
    writeLines(c("make -j\n"), fileConn)

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

    writeLines(c("export OMP_NUM_THREADS=1",
                 paste("PREFIX=", prefix,sep=""),
                 paste("OUTPUT=",outputfile,sep=""),
                 paste("MODEL=",modelfile,sep=""),
                 paste("DESIGNMAT=",designmat,sep=""),
                 "\n",
                 "masks:= $(wildcard $(PREFIX)????.nii.gz)",
                 "outputs:=$(masks:%.nii.gz=%$(OUTPUT))",
                 "\n",
                 paste(alltarget,collapse=" "),
                 "\n",
                 "%$(OUTPUT): %.nii.gz\n\tnpointrun -m $< --model $(MODEL) -d $(DESIGNMAT)",
                 "\n",
                 allrules,
                 "\n",
                 paste(mostlyclean,collapse=""),
                 clean),
               fileConn)
}
