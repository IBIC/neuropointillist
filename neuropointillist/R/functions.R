#### Check that for each set of files provided, there is a matching
#### covariate file
checkSetLabels <- function(set, setlabels) {
    if((!is.null(set) & is.null(setlabels)) ||
       (is.null(set) & !is.null(setlabels))) {
        stop("Must specify setlabels for each data set.")
    }
}

#### Perform additional argument checks.
# At least one data set must be provided
# only one method of parallelization should be specified
checkArguments <- function(args) {
    checkSetLabels(args$set1,args$setlabels1)
    checkSetLabels(args$set2,args$setlabels2)
    checkSetLabels(args$set3,args$setlabels3)
    checkSetLabels(args$set4,args$setlabels4)        
    checkSetLabels(args$set5,args$setlabels5)        

    if (is.null(args$set1)) {
        stop("Must specify at least one data set.")
    }

    # Make sure only one method of parallelization was specified
    if (!is.null(args$processors) & !is.null(args$sgeN)) {
        stop("Cannot use both SGE and multicore parallelization.")
    }
}
    
#### Read the files that are in each data set and put them into the
#### args structure
readSetFiles <- function(args) {
    if (!is.null(args$set1)) {
        filelist <- read.table(args$set1,stringsAsFactors=FALSE)
        args$set1 <- filelist$V1
    }
    if (!is.null(args$set2)) {
        filelist <- read.table(args$set2,stringsAsFactors=FALSE)
        args$set2 <- filelist$V1
    }        
    if (!is.null(args$set3)) {
        filelist <- read.table(args$set3,stringsAsFactors=FALSE)
        args$set3 <- filelist$V1
    }
    if (!is.null(args$set4)) {
        filelist <- read.table(args$set4,stringsAsFactors=FALSE)
        args$set4 <- filelist$V1
    }
    if (!is.null(args$set5)) {
        filelist <- read.table(args$set5,stringsAsFactors=FALSE)
        args$set5 <- filelist$V1
    }
    return(args)
}


#' Read in neuroimaging data from argument structure
#'
#' This function takes an argument structure that specifies all the parameters
#' that should be input to npointillist and returns an array of voxel data and
#' a covariate matrix.
#' @param args Arguments for neuropointillist
#' @param numberdatasets The number of data sets specified in args
#' @param mask.vertices A vector of vertices used to determine what vertices to read
#' npointReadDataSets()
npointReadDataSets <- function(args, numberdatasets, mask.vertices) {
    alldat <- c()
    covariates <- c()
    dataset<-1
    dims <- c()

    # preallocate data using the total number of files and the size of the first file

    firstfile <- args$set1[1]
    nii <- nifti.image.read(firstfile)
    dims <- dim(nii)
    is3d <- length(dims)==3
    is4d <- length(dims)==4
    if (!is3d && !is4d) {
        stop("Only 3 or 4 dimensional data is currently supported.")
    }

    totalnumberdatasets <- length(args$set1) + length(args$set2) + length(args$set3) + length(args$set4) + length(args$set5)
    
    cat("Allocating memory for data.\n")
    if (is3d) {
        system.time(voxeldat <- matrix(nrow=totalnumberdatasets, ncol=length(mask.vertices)))
    } else { #4d
        nvolumes <- dims[4]
        system.time(voxeldat <- matrix(nrow=nvolumes*totalnumberdatasets, ncol=length(mask.vertices)))
    }

    cat("Reading in data.\n")
    i <- 1
    while(dataset <= numberdatasets) {
        cat("\t++Working on dataset", dataset, "\n")
        set.files <- eval(parse(text=paste("args$set", dataset, sep="")))
        set.covariates <- eval(parse(text=paste("args$setlabels", dataset, sep="")))
        covars <- read.csv(set.covariates,stringsAsFactors=FALSE)
        # bind covariates together
        if (is.null(covariates)) {
            covariates <- covars
        } else {
            covariates <- rbind(covariates,covars)
        }
        
        for(file in set.files) {
            nii <- nifti.image.read(file)
            stopifnot(dims == dim(nii)) #check that dimensions are the same
            if (is3d) {
                ndat <- nii[,,]
                dim(ndat) <- prod(dims)
                                        # reduce to a set of vertices
                ndat <- ndat[mask.vertices]
                voxeldat[i,] <-ndat
                i <- i+1
            } else {#is4d
                ndat <- nii[,,,]
                dim(ndat) <- c(prod(dims[1:3]),dims[4])
                ndat <- t(ndat)
                ndat <- ndat[,mask.vertices]
                voxeldat[i:(nvolumes+i-1),] <-ndat                
                i <- i+nvolumes
            }
        }
        if (is3d) {
            expectedlength <- length(set.files)
        } else {
            expectedlength <- length(set.files)*nvolumes
        }
        if (dim(covars)[1] != expectedlength) {
            cat("Check your input data!!!\n")
            if (is3d) {
                cat("Number of rows in covariate file is not equal to the number of data sets\n")
            stop(paste("There are ", dim(covars)[1], "covariates for", length(set.files), "files in set", dataset))                
            } else {# is4d
                cat("Number of rows in covariate file is not equal to the number of data sets multiplied by the number of volumes in each set\n")                                
                stop(paste("There are ", dim(covars)[1], "covariates for", length(set.files), "files in set", dataset))
            }

        }
        dataset <- dataset+1
    }
    return(list(covariates=covariates,voxeldat=voxeldat))
}


warnIfNiiFileExists <- function(filename) {
    if (file.exists(filename)) {
        newfilename <- gsub(".nii", "-.nii", filename)
        warning(paste("The output file", filename, "exists. Renaming to", newfilename))
        file.rename(filename,newfilename)
    }
}



#### Write out a nifti file of vertexdata, given a mask
writeFile <- function(mask, vertexdata,outputfilename) {
# check if file exists and rename
    warnIfNiiFileExists(outputfilename)
    mask.dims <- dim(mask)
    len <- mask.dims[1]*mask.dims[2]*mask.dims[3]
    mask.vector <- as.vector(mask[,,])
    mask.vertices <- which(mask.vector >0)
    # make sure that we are filling in data of the right size
    # there are two options - either there is one value per vertex
    # or the output is four dimensional
    is3d <-length(mask.vertices)==length(vertexdata)
    is4d <- length(mask.vertices) < length(vertexdata)
    stopifnot(is3d || is4d)
    if (is3d) {
        y <- vector(mode="numeric", length=len)
        y[mask.vertices] <- vertexdata
        nim <- nifti.image.copy.info(mask)
        nim$dim <- mask.dims
        nifti.image.alloc.data(nim)
        nim[,,] <- as.array(y,mask.dims)
        nifti.set.filenames(nim, outputfilename)
        nifti.image.write(nim)
    } else {# a 4d image
        # check for even multiple of volumes
        nvolumes <- length(vertexdata)/length(mask.vertices)
        nvolumes.trunc <- trunc(nvolumes)
        if (nvolumes != nvolumes.trunc) {
            cat("processVoxel returned a 4d volume that is not an even multiple of the mask.\n")
            stop("Check your processVoxel function.")
        }
        y <- vector(mode="numeric", length=len)        
        y[mask.vertices] <- 1
        y <- rep(y, nvolumes)
        y[y==1] <- vertexdata
        nim <- nifti.image.copy.info(mask)
        dims <- c(mask.dims, nvolumes)
        nim$dim <- dims
        nifti.image.alloc.data(nim)
        nim[,,,] <- as.array(y,dims)
        nifti.set.filenames(nim, outputfilename)
        nifti.image.write(nim)
    }
        
}


#' Write the output statistic files
#'
#' This function takes an argument structure that specifies all the parameters
#' that should be input to npointillist and returns an array of voxel data and
#' a covariate matrix.
#' @param prefix Prefix for output, to be prepended to outputs
#' @param results A vector of lists returned from the processVoxel function
#' @param mask A mask that corresponds to the output results
#' npointWriteOutputFiles()
npointWriteOutputFiles <- function(prefix, results, mask) {
   # make sure that any directory specified by prefix exists
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    names <- attributes(results[,1])$names
    for(i in 1:dim(results)[1]) {
        statistic <- names[i]
        outputfilename <- paste(prefix, statistic, ".nii.gz", sep="")
        writeFile(mask, unlist(results[i,]),outputfilename)
    }
}
    

#### split mask and data into chunks of the specified size
npointSplitDataSize <- function(size, prefix, mask) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
# reduce mask to list of vertices
    mask.dims <- dim(mask)
    len <- mask.dims[1]*mask.dims[2]*mask.dims[3]
    mask.vector <- as.vector(mask[,,])
    mask.vertices <- which(mask.vector >0)
	d1 <- split(mask.vertices, ceiling(seq_along(mask.vertices)/(size) - 1)
#	d1 <- split(mask.vertices, size - 1)
	print(d1)
    start <- 1
    for (i in 1:length(d1)) {
        y <- vector(mode="numeric",length=len)
        y[unlist(d1[i])] <- 1
        nim <- nifti.image.copy.info(mask)
        nim$dim <- dim(mask)
        nifti.image.alloc.data(nim)
        nim[,,] <- as.array(y,mask.dims)
        outputfilename <- paste(prefix, sprintf("%04d",i),".nii.gz",sep="")
        warnIfNiiFileExists(outputfilename)
        nifti.set.filenames(nim, outputfilename)
        nifti.image.write(nim)
                      # now subdat the data
        sz <- length(unlist(d1[i]))
        saveRDS(voxeldat[,start:(start+sz-1)], paste(prefix, sprintf("%04d",i),".rds",sep=""))
        start <- start+sz
        
    }
    return(length(d1)) #return the number of jobs it got split into
}


#' Write an output makefile
#'
#' Generate a makefile for the given workflow
#' @param prefix Prefix for output, to be prepended to outputs
#' @param resultnames List of names for the expected outputs
#' @param modelfile Name of the model file that contains the processVoxel command
#' @param designmat Design matrix
#' @param makefile Name of makefile
#' npointWriteMakefile()
npointWriteMakefile <- function(prefix, resultnames, modelfile, designmat, makefile) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    # the name of one of the outputfiles that is created
    outputfile <- paste(resultnames[1], ".nii.gz",sep="")
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
    

mergeDesignmatWithCovariates <- function(desigmat, covariatefile) {
    covariates <- read.csv(covariatefile,stringsAsFactors=FALSE)
    common <- intersect(colnames(designmat), colnames(covariates))
    if(length(common) == 0) {
        stop("Headers in covariate file do not match any in design matrix.")
    } else {
        cat("Merging ", length(common), " covariate fields with design matrix\n")
    }
    # merge design matrix and covariates
    merged <-merge(designmat, covariates,by=common)
    if (length(merged)==0) {
        cat("After merging nothing was left in the design matrix!")
        stop("Check your covariate file!")
    }
    if (dim(voxeldat)[1] != dim(merged)[1]) {
        cat("After merging the dimension of the design matrix no longer matches the fmri data\n")
        stop("Check your covariate file!")
    }

return(merged)
}

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
                 "# This script will submit jobs to SGE. You can also run this with make.",
                 paste("qsub -sync y", basename(jobscript)),
                 "make"),
               fileConnMaster)

#                 "qsub -hold_jid npoint sleep",


    writeLines(c("#!/bin/bash",
                 "\n",
                 "export OMP_NUM_THREADS=1",
                 "#SGE submission options",
                 "#$ -cwd",
                 "#$ -V",
                 paste("#$ -t 1-", njobs, sep=""),
                 "#$ -N npoint",
                 paste("MODEL=",modelfile,sep=""),
                 paste("DESIGNMAT=",designmat,sep=""),
                 "num=$(printf \"%04d\" $SGE_TASK_ID)",
                 paste("npointrun -m ", basename(prefix), "${num}.nii.gz --model ${MODEL} -d ${DESIGNMAT}",sep=""),
                 "\n"),
               fileConnJob)
    Sys.chmod(masterscript, "775")
}

