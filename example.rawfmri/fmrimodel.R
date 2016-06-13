# This model is written so that errors are appropriately trapped and
#handled when running
# using a shared memory multiprocessor
library(nlme)

processVoxel <-function(v) {
    Y <- voxeldat[,v]
    e <- try(mod1 <- lme(Y ~ AllCue+AllCueDerivative+AllTarget+AllTargetDerivative+conf1+conf2+conf3+conf4+conf5+conf6+conf7+conf8+conf9+conf10 +conf11+conf12+conf13+conf14, random=~1|idnum, method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
    if(inherits(e, "try-error")) {
        mod1 <- NULL
    }
    if(!is.null(mod1)) {
        retvals <- list(summary(mod1)$tTable["AllCue", "t-value"],
                        summary(mod1)$tTable["AllTarget", "t-value"])
    } else {
    # If we are returning 4 dimensional data, we need to be specify how long
    # the array will be in case of errors
        retvals <- list(999,999)
    }
    names(retvals) <- c("tstat-AllCue", "tstat-AllTarget")
    retvals
}

