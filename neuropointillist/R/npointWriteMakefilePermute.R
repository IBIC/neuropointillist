
#' Write an output makefile for permutation testing
#'
#' Generate a makefile for running a specific analysis
#' @param prefix Prefix for output, to be prepended to outputs
#' @param resultnames Names of results from processvoxel. You can return multiple permutation statistics, with names, and they will be used to write multiple permutation files
#' @param modelfile Name of the R model file that contains the processVoxel command
#' @param designmat Design matrix
#' @param makefile Name of makefile
#' @param localscript Name of script to execute makefile locally
#' @param npermutations Number of permutations to run#' 
#' @export
npointWriteMakefilePermute <- function(prefix, resultnames, modelfile, designmat, makefile, localscript, npermutations) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    # the names of the outputfiles that are created
    outputfiles <- paste(paste("%", "permute", ".nii.gz",sep=""),collapse=" ")


    # write out the little local script for running this
    fileConn <- file(localscript)
    writeLines(c("make -j 4\n"), fileConn)
    Sys.chmod(localscript, "775")
    close(fileConn)

    fileConn <- file(makefile)


    clean <- "clean:\n\trm -f *.rds $(mask) npoint.e* npoint.o*"     
    


    systemname <- Sys.info()["sysname"]
    msrelease <- grep("Microsoft", Sys.info()["release"])
    if (systemname=="Linux") {
        # if we are on Microsoft UNIX don't time
        if (length(msrelease) > 0) {
            timecommand <- ""
       # if anything else we are ok
        } else {
            timecommand <- "/usr/bin/time --verbose"
        }
    } else if (systemname=="Darwin") {
       # mac uses the -l flag
        timecommand <- "/usr/bin/time -l"
    } else {
        # if we can't figure it out don't do anything
        timecommand <- ""        
    }
    
    writeLines(c("#Set the number of threads to be 1 to avoid overloading single cores\n",
                 "export OMP_NUM_THREADS=1",
                 paste("PREFIX=", prefix,sep=""),
                 paste("NPERMUTE=",npermutations,sep=""),
                 "PERMUTATIONS=$(shell seq -w 1 $(NPERMUTE))",
                 paste("outputs=$(addprefix ", head(resultnames), ".", ", ", "$(addsuffix permute.nii.gz, $(PERMUTATIONS))) ", sep=""),
                 paste("MODEL=",modelfile,sep=""),
                 paste("DESIGNMAT=",designmat,sep=""),
                 "MASK= $(wildcard $(PREFIX)????.nii.gz)",
                 "# You can change or remove the time command. This is to gauge memory allocation and time to allow for completion on clusters.\n",
                 paste("TIME=", timecommand, sep=""),
                 "\n",
                 "all: $(outputs)",
                 "\n",
                 "%permute.nii.gz: $(MASK)\n\t$(TIME) npointrun -m $< --model $(MODEL) --permutationfile $@ -d $(DESIGNMAT)",
                 "\n",
                 clean),
               fileConn)
    close(fileConn)

}
