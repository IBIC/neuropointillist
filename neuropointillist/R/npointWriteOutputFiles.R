
#' Write the output statistic files
#'
#' This function takes an argument structure that specifies all the parameters
#' that should be input to npointillist and returns an array of voxel data and
#' a design matrix.
#' @param prefix Prefix for output, to be prepended to outputs
#' @param results Data returned from the processVoxel function
#' @param mask A nifti mask that corresponds to the output results
#' @export
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
        npointWriteFile(mask, unlist(results[i,]),outputfilename)
    }
}
