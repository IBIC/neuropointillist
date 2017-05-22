# This model is written so that errors are appropriately trapped and
#handled when running
# using a shared memory multiprocessor
library(nlme)

processVoxel <-function(v) {
    Y <- voxeldat[,v]
    e <- try(mod <- lme(Y ~ High+Low, random=~1|subject, method=c("ML"), na.action=na.omit, corr=corAR1(form=~1|subject), control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
    if(inherits(e, "try-error")) {
        mod <- NULL
    }
    if(!is.null(mod)) {
        contr <- c(0, 1,-1)
        out <- anova(mod,L=contr)
        t.stat <- (t(contr)%*%mod$coefficients$fixed)/sqrt(t(contr)%*%vcov(mod)%*%contr)
        p <- 1-pt(t.stat,df=out$denDF)
        retvals <- list(summary(mod)$tTable["High", "t-value"],
                        summary(mod)$tTable["Low", "t-value"], t.stat, p)
    } else {
    # If we are returning 4 dimensional data, we need to be specify how long
    # the array will be in case of errors
        retvals <- list(999,999,999,999)
    }
    names(retvals) <- c("tstat-High", "tstat-Low", "tstat-High.gt.Low", "p-High.gt.Low")
    retvals
}

