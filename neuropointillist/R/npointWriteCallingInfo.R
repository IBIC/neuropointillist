#' Write information that describes how npointillist was called
#'
#' Write information that describes how npointillist was called
#' @param args Arguments provided to npointillist
#' @export
npointWriteCallingInfo <- function(args) {
    dir <- dirname(args$output)
    if (!dir.exists(dir)) {
        dir.create(dir, recursive=TRUE)
    }
    
    # the name of one of the outputfiles that is created
    outputfile <- paste(dir, "readargs.R",sep="/")

    # make a copy of the model file
    modelcopy <- paste(dir, basename(args$model),sep="/")
    file.copy(args$model, modelcopy)               

    # open file connection
    fileConn <- file(outputfile)

    datasets <- paste("\"--set1\"", ", \"", normalizePath(args$set1), "\",",
                      "\"--setlabels1\"", ", \"", normalizePath(args$setlabels1), "\",", sep="")

    if (!is.null(args$set2)) {
        datasets <- paste(datasets, "\"--set2\"", ", \"", normalizePath(args$set2), "\",",
                          "\"--setlabels2\"", ", \"", normalizePath(args$setlabels2), "\",", sep="")
    }


    if (!is.null(args$set3)) {
        datasets <- paste(datasets, "\"--set3\"", ", \"", normalizePath(args$set3), "\",",
                          "\"--setlabels3\"", ", \"", normalizePath(args$setlabels3), "\",", sep="")
    }


    if (!is.null(args$set4)) {
        datasets <- paste(datasets, "\"--set4\"", ", \"", normalizePath(args$set4), "\",",
                          "\"--setlabels4\"", ", \"", normalizePath(args$setlabels4), "\",", sep="")
    }


    if (!is.null(args$set5)) {
        datasets <- paste(datasets, "\"--set5\"", ", \"", normalizePath(args$set5), "\",",
                          "\"--setlabels5\"", ", \"", normalizePath(args$setlabels5), "\",", sep="")
    }

    if (!is.null(args$covariates)) {
        datasets <-   paste(datasets, "\"--covariates\"", ",", "\"", normalizePath(args$covariates), "\"", ",", sep="")
    }

    parallelFlags <- NULL
    if (!is.null(args$processors)) {
        parallelFlags <- paste("\"--processors\"", ", \"", args$processors, "\"", sep="")
    } else  if (!is.null(args$sgeN)) {
            parallelFlags <- paste("\"--sgeN\"", ", \"", args$sgeN, "\"", sep="")
    } else  if (!is.null(args$pbsN)) {
        parallelFlags <- paste("\"--pbsN\"", ", \"", args$pbsN, "\"", sep="")
        
    } else  if (!is.null(args$slurmN)) {
        parallelFlags <- paste("\"--slurmN\"", ", \"", args$slurmN, "\"", sep="")    
    }
    if (!is.null(args$pbsPre)) {
        parallelFlags <- paste(parallelFlags, ", \"--pbsPre\"", ", \"", normalizePath(args$pbsPre), "\"", sep="")
    }

    permuteFlag <- NULL
    if (!is.null(args$permute)) {
        permuteFlag <- paste("\"--permute\"", ", \"", args$permute, "\"", sep="")        
    }

    debugfile <- NULL
    if (!is.null(args$debugfile)) {
        debugfile <- args$debugfile
    }


    writeLines(c(paste("cmdargs <- c(\"-m\"", ",", "\"", normalizePath(args$mask), "\",", sep=""),
                 datasets,
                 paste("\"--model\"", ",", "\"",  normalizePath(args$model), "\"", ",", sep=""),
                 paste("\"--output\"", ",", "\"", args$output, "\"", ",", sep=""),
                 debugfile,
                 parallelFlags,
                 ")" ),
               fileConn)
}

