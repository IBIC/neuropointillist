#' Read in neuroimaging data from argument structure
#'
#' This function takes an argument structure that specifies all the parameters
#' that should be input to npointillist and returns an array of voxel data and
#' a design matrix.
#' @param args Arguments for neuropointillist
#' @param numberdatasets The number of data sets specified in args
#' @param mask.vertices A vector of vertices used to determine what vertices to read
#' @export
#' @return designmat Data structure containing designmat
#' @return voxeldat Data structure containing the masked voxel data
#'
npointReadDataSets <- function(args, numberdatasets, mask.vertices) {
    alldat <- c()
    designmat <- c()
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
        set.designmat <- eval(parse(text=paste("args$setlabels", dataset, sep="")))
        covars <- read.csv(set.designmat,stringsAsFactors=FALSE)
        # bind designmat together
        if (is.null(designmat)) {
            designmat <- covars
        } else {
            designmat <- rbind(designmat,covars)
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
                cat("Number of rows in setlabels file is not equal to the number of data sets\n")
            stop(paste("There are ", dim(covars)[1], "variables for", length(set.files), "files in set", dataset))                
            } else {# is4d
                cat("Number of rows in covariate file is not equal to the number of data sets multiplied by the number of volumes in each set\n")                                
                stop(paste("There are ", dim(covars)[1], "variables for", length(set.files), "files in set", dataset))
            }

        }
        dataset <- dataset+1
    }
    return(list(designmat=designmat,voxeldat=voxeldat))
}
