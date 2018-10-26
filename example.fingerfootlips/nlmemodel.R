# This model is written so that errors are appropriately trapped and
#handled when running
# using a shared memory multiprocessor
library(nlme)

processVoxel <-function(v) {
    BRAIN <- voxeldat[,v]
    e <- try(mod <- lme(BRAIN ~ Finger+Foot+Lips+WhiteMatter+X+Y+Z+RotX+RotY+RotZ, random=~1|idnum, method=c("ML"), na.action=na.omit, corr=corAR1(form=~1|idnum), control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
    if(inherits(e, "try-error")) {
        mod <- NULL
    }
    if(!is.null(mod)) {
        #finger contrast
        contr <- c(0, 1, 0, 0, 0, 0,0,0,0,0,0)
        out <- anova(mod,L=contr)
        finger.t.stat <- (t(contr)%*%mod$coefficients$fixed)/sqrt(t(contr)%*%vcov(mod)%*%contr)
        finger.p<-1-out$"p-value"        

        #foot contrast
        contr <- c(0, 0, 1, 0, 0, 0,0,0,0,0,0)
        out <- anova(mod,L=contr)
        foot.t.stat <- (t(contr)%*%mod$coefficients$fixed)/sqrt(t(contr)%*%vcov(mod)%*%contr)
        foot.p <- 1-out$"p-value"        

        #lips contrast
        contr <- c(0, 0, 0, 1, 0, 0,0,0,0,0,0)
        out <- anova(mod,L=contr)
        lips.t.stat <- (t(contr)%*%mod$coefficients$fixed)/sqrt(t(contr)%*%vcov(mod)%*%contr)
        lips.p <- 1-out$"p-value"        

        retvals <- list(finger.t.stat, finger.p, foot.t.stat, foot.p, lips.t.stat, lips.p)

    } else {
    # If we are returning 4 dimensional data, we need to be specify how long
    # the array will be in case of errors
        retvals <- list(999,999,999,999,999,999)
    }
    names(retvals) <- c("finger.tstat", "finger.p", "foot.tstat", "foot.p", "lips.tstat", "lips.p")
    retvals
}

