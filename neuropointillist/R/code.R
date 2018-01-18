#' Check Set Labels
#'
#' Argument checking to make sure there are labels for each data set.
#' @param set Set filename
#' @param setlabels Lables for items in set filename
#' 
npointCheckSetLabels <- function(set, setlabels) {
    if((!is.null(set) & is.null(setlabels)) ||
       (is.null(set) & !is.null(setlabels))) {
        stop("Must specify setlabels for each data set.")
    }
}

#' Check Input Arguments
#'
#' Check input arguments. At least one data set must be provided, and only
#' one method of parallelization should be specified
#' @param args Arguments
#' @export
#' @return args Modified argument structure, with set files replaced with actual list of files
npointCheckArguments <- function(args) {
    if (!is.null(args$output)) {
        lastchar = substr(args$output,nchar(args$output), nchar(args$output))
        if (lastchar=="/") {
            warning(paste("You have specified output should be prefixed with ", args$output))
            stop(paste("If you are intending to specify an output directory, you must give a prefix after the trailing slash, for example", paste(args$output, "pre.")))
        }
    }

    npointCheckSetLabels(args$set1,args$setlabels1)
    npointCheckSetLabels(args$set2,args$setlabels2)
    npointCheckSetLabels(args$set3,args$setlabels3)
    npointCheckSetLabels(args$set4,args$setlabels4)        
    npointCheckSetLabels(args$set5,args$setlabels5)        

    if (is.null(args$set1)) {
        stop("Must specify at least one data set.")
    }

    # Make sure only one method of parallelization was specified
    if (!is.null(args$processors) & !is.null(args$sgeN)) {
        stop("Cannot use both SGE and multicore parallelization.")
    }
    args <- npointReadSetFiles(args)
    return(args)
}
    
#' Read Set Files
#'
#' Read in the files that are in each data set and put them into the args
#' structure.
#' @param args Arguments
#' return args Modified argument structure, with set files replaced with actual list of files
npointReadSetFiles <- function(args) {
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


#' Warn if NifTI File Exists
#'
#' Warn if a nifti file exists, and rename it if it does
#' @param filename Nifti filename
npointWarnIfNiiFileExists <- function(filename) {
    if (file.exists(filename)) {
        newfilename <- gsub(".nii", "-.nii", filename)
        warning(paste("The output file", filename, "exists. Renaming to", newfilename))
        file.rename(filename,newfilename)
    }
}



#' Write out a NifTI file of voxel data
#'
#' Take a vector of voxel data and a mask and reassemble it into
#' an output NifTI file. Make sure that the output file is floating point
#' or nasty truncation can occur. You want floats, right? 
#' @param mask NifTI mask corresponding to voxel data
#' @param voxeldata Vector of voxel data
#' @param outputfilename 
npointWriteFile <- function(mask, voxeldata,outputfilename) {
# check if file exists and rename
    npointWarnIfNiiFileExists(outputfilename)
    mask.dims <- dim(mask)
    len <- mask.dims[1]*mask.dims[2]*mask.dims[3]
    mask.vector <- as.vector(mask[,,])
    mask.vertices <- which(mask.vector >0)
    # make sure that we are filling in data of the right size
    # there are two options - either there is one value per vertex
    # or the output is four dimensional
    is3d <-length(mask.vertices)==length(voxeldata)
    is4d <- length(mask.vertices) < length(voxeldata)
    stopifnot(is3d || is4d)
    if (is3d) {
        y <- vector(mode="numeric", length=len)
        y[mask.vertices] <- voxeldata
        nim <- nifti.image.copy.info(mask)
        nifti.image.setdatatype(nim, "NIFTI_TYPE_FLOAT32")
        nim$dim <- mask.dims
        nifti.image.alloc.data(nim)
        nim[,,] <- as.array(y,mask.dims)
        nifti.set.filenames(nim, outputfilename)
        nifti.image.write(nim)
    } else {# a 4d image
        # check for even multiple of volumes
        nvolumes <- length(voxeldata)/length(mask.vertices)
        nvolumes.trunc <- trunc(nvolumes)
        if (nvolumes != nvolumes.trunc) {
            cat("processVoxel returned a 4d volume that is not an even multiple of the mask.\n")
            stop("Check your processVoxel function.")
        }
        y <- vector(mode="numeric", length=len)        
        y[mask.vertices] <- 1
        y <- rep(y, nvolumes)
        y[y==1] <- voxeldata
        nim <- nifti.image.copy.info(mask)
        nifti.image.setdatatype(nim, "NIFTI_TYPE_FLOAT32")
        dims <- c(mask.dims, nvolumes)
        nim$dim <- dims
        nifti.image.alloc.data(nim)
        nim[,,,] <- as.array(y,dims)
        nifti.set.filenames(nim, outputfilename)
        nifti.image.write(nim)
    }
        
}



#' Split Data
#'
#' Split an input mask and data into chunks of the specified size.
#' @param size Number of voxels in each chunk
#' @param voxeldat Voxel data
#' @param prefix Text prefix to prepend to the output files
#' @param mask Nifti mask to split
#' @export
npointSplitDataSize <- function(size, voxeldat, prefix, mask) {
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
# reduce mask to list of vertices
    mask.dims <- dim(mask)
    len <- mask.dims[1]*mask.dims[2]*mask.dims[3]
    mask.vector <- as.vector(mask[,,])
    mask.vertices <- which(mask.vector >0)
    d1 <- split(mask.vertices,  ceiling(seq_along(mask.vertices)/(size)))
    start <- 1
    for (i in 1:length(d1)) {
        y <- vector(mode="numeric",length=len)
        y[unlist(d1[i])] <- 1
        nim <- nifti.image.copy.info(mask)
        nim$dim <- dim(mask)
        nifti.image.alloc.data(nim)
        nim[,,] <- as.array(y,mask.dims)
        outputfilename <- paste(prefix, sprintf("%04d",i),".nii.gz",sep="")
        npointWarnIfNiiFileExists(outputfilename)
        nifti.set.filenames(nim, outputfilename)
        nifti.image.write(nim)
                      # now subdat the data
        sz <- length(unlist(d1[i]))
        saveRDS(voxeldat[,start:(start+sz-1)], paste(prefix, sprintf("%04d",i),".rds",sep=""))
        start <- start+sz
        
    }
    return(length(d1)) #return the number of jobs it got split into
}

    
#' Merge the Design Matrix With Covariates 
#'
#' Take the assembled design matrix and merge it with any covariates, making
#' sure that the output is reasonable.
#' @param designmat Design matrix
#' @param covariatefile Covariate csv file
#' @param voxeldatdim Dimensions of voxel data
#' @export
npointMergeDesignmatWithCovariates <- function(desigmat, covariatefile,voxeldatdim) {
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
    if (voxeldatdim != dim(merged)[1]) {
        cat("After merging the dimension of the design matrix no longer matches the fmri data\n")
        stop("Check your covariate file!")
    }

return(merged)
}

