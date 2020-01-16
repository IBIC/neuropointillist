
#' Write the output statistic files
#'
#' This function takes an argument structure that specifies all the parameters
#' that should be input to npointillist and returns an array of voxel data and
#' a design matrix.
#' @param prefix Prefix for output, to be prepended to outputs
#' @param results Data returned from the processVoxel function
#' @param mask A nifti mask that corresponds to the output results
#' @param rds Save rds file instead of nii? Default is FALSE.
#' @export
npointWriteOutputFiles <- function(prefix, results, mask, rds=FALSE) {
   # make sure that any directory specified by prefix exists
    dir <- dirname(prefix)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    #if user requested rds file output, do that instead of writing nii files.
    if(rds){
        outputfilename <- paste(prefix, ".rawresults.rds", sep="")
        saveRDS(results, file=outputfilename, compress = FALSE)
    } else {
    # test to see if more than one name was returned 
        if(is.array(results)) {
            names <- attributes(results[,1])$names
            for(i in 1:dim(results)[1]) {
                statistic <- names[i]
                outputfilename <- paste(prefix, statistic, ".nii.gz", sep="")
                npointWriteFile(mask, unlist(results[i,]),outputfilename)
            }
        } else {
            statistic <- attributes(results)$names[1]
            outputfilename <- paste(prefix, statistic, ".nii.gz", sep="")
            npointWriteFile(mask, unlist(results),outputfilename)
        }
    }
}
