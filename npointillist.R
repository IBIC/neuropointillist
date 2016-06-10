# print a warning if we don't have the necessary functions, to provide a bit
# more helpful information
require(Rniftilib)
require(argparse)
require(doParallel)

library(Rniftilib)
library(argparse)
library(doParallel)

# Source helper functions
source("helper.R")

parser <- ArgumentParser()
parser$add_argument("-m", "--mask", nargs=1,type="character", help="Mask limiting the voxels that will be analyzed",required=TRUE)
parser$add_argument( "--set1", nargs=1,  help="List of files at first occasion")
parser$add_argument( "--set2", nargs=1, help="List of files at second occasion")
parser$add_argument("--set3", nargs=1, help="List of files at third occasion")
parser$add_argument("--set4", nargs=1, help="List of files at fourth occasion")
parser$add_argument("--set5", nargs=1, help="List of files at fifth occasion")

parser$add_argument("--setlabels1",  nargs=1, help="Covariates for files at first occasion")
parser$add_argument("--setlabels2",  nargs=1, help="Covariates for files at second occasion")
parser$add_argument("--setlabels3",  nargs=1, help="Covariates for files at third occasion")
parser$add_argument("--setlabels4",   nargs=1,help="Covariates for files at fourth occasion")
parser$add_argument("--setlabels5",   nargs=1, help="Covariates for files at fifth occasion")

parser$add_argument("--model", nargs=1, help="R code that defines the voxelwise-model and any initialization", required=TRUE)
parser$add_argument("--covariates", nargs=1,type="character", help="Covariates that will be merged with the design matrix")
parser$add_argument("--output", nargs=1,type="character", help="Output prefix to prepend to output files")
parser$add_argument("--debugfile", nargs=1,type="character", help="Save voxeldat and designmat objects to this file to develop, test and debug the processVoxel function")

parser$add_argument("-p", "--processors", type="integer", help="Run using shared memory with p processors")
parser$add_argument("--sgeN",  type="integer", nargs=1, help="Run using SGE generating N jobs")


source("readargs.R")

args <- parser$parse_args(cmdargs)


#### Check for mask and read it. It is mandatory and must exist.
maskfile <- args$mask
tryCatch({
    mask <- nifti.image.read(maskfile);
}, error=function(e) {
    cat("Could not read mask file: ", maskfile, "\n")
    stop(e)
})

# reduce to vector and obtain list of nonzero vertices
mask.vector <- as.vector(mask[,,])
mask.vertices <- which(mask.vector > 0)

#### Do argument checking
checkArguments(args)


#### Are we running in parallel?
if (!is.null(args$processors) || !is.null(args$sgeN)) {
    runningParallel =TRUE
} else {
    runningParallel= FALSE
}
    

#### Read in set files and modify argument structure
args <- readSetFiles(args)


###############################################################################
#### Calculate the number of data sets
numberdatasets <- sum(!is.null(args$set1),
                          !is.null(args$set2),
                          !is.null(args$set3),
                          !is.null(args$set4),
                          !is.null(args$set5))

###############################################################################
#### Read in all the data sets

cat("Reading", numberdatasets, "data sets.\n")
data <- readDataSets(args,numberdatasets,mask.vertices);
voxeldat <- data$voxeldat
designmat <-data$covariates
rm(data)
gc()

###############################################################################
#### Read in covariates if specified and merge with other covariates specified
#### on the command line
if (!is.null(args$covariates)) {
    designmat <- mergeDesignmatWithCovariates(designmat,args$covariates)
}

###############################################################################
### If debugging file is specified, save out design matrix and voxel matrix
### to this file
if(!is.null(args$debugfile)) {
    save(designmat,voxeldat, file=args$debugfile)
}

###############################################################################
#### read model code
if (!is.null(args$model)) {
    modelfile <- args$model
    if (!file.exists(modelfile)) {
        stop("model file ", modelfile, " does not exist!")
    }
    result <- tryCatch({
        source(modelfile)
    }, error=function(e) {
        cat("There were errors in the model file ", modelfile, "\n")
        stop(e)

    })
}

###############################################################################
#### Do the parallel processing

nvertices <- length(mask.vertices)
if (runningParallel) {
    if (!is.null(args$processors)) {
        attach(designmat) # we attach to the designmat
        cl <- makeCluster(args$processors, type="FORK")
        cat("Exporting data to cluster.\n")
        clusterExport(cl,varlist=c("voxeldat"))
        cat("Starting parallel job using", args$processors, "cores.\n")
        cat("Use top to make sure that no threads are using more than 100% of the CPU.\n")
        system.time(results <-parSapply(cl,1:nvertices, processVoxel))
        stopCluster(cl)
        writeOutputFiles(args$output,results,mask)
    } else { # we are using SGE
        # split up the data into chunks and write out scripts to process
        if (args$sgeN > nvertices) {
            stop("Number of SGE jobs requested is greater than the number of vertices")
        }
        size <- trunc(nvertices/args$sgeN)
        njobs <- splitDataSize(size,args$output,mask)
        # save the design matrix
        designmatname <- paste(args$output, "designmat.rds", sep="")
        makefilename <- paste(dirname(args$output), "/Makefile", sep="")
        masterscript <- paste(dirname(args$output), "/runme", sep="")
        jobscript <- paste(dirname(args$output), "/sgejob.bash", sep="")
        saveRDS(designmat,designmatname)
        attach(designmat) # attach to the designmat
        out <- processVoxel(1) # test one voxel to obtain names for return vals
        writeMakefile(basename(args$output), names(out), paste(getwd(), "/",args$model,sep=""), basename(designmatname), makefilename)
        writeSGEsubmitscript(basename(args$output), names(out), paste(getwd(), "/",args$model,sep=""), basename(designmatname), masterscript,jobscript, njobs) 
    }
} else {
    cat("Starting sequential job\n")
    cat("You might want to check whether your model is multithreaded\n")
    cat("because your code might run faster if you limit the number of threads\n")
    system.time(results <-sapply(1:nvertices, processVoxel))
    writeOutputFiles(args$output,results,mask)    
}


        
                



