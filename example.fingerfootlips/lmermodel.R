# This model is written so that errors are appropriately trapped and
#handled when running
# using a shared memory multiprocessor
library(lme4)

# Note that lme4 functions do not report p-values. This package incorporates p-values into the output of the functions lmer and anova.
library(lmerTest)

processVoxel <-function(v) {
    BRAIN <- voxeldat[,v]
    e <- try(mod<-lmer(BRAIN ~ Finger+Foot+Lips+WhiteMatter+X+Y+Z+RotX+RotY+RotZ + (1 + Finger+Foot+Lips|idnum) + (1|time), REML = FALSE))
    if(inherits(e, "try-error")) {
        mod <- NULL
    }

    if(!is.null(mod)) {
        # finger contrast 
        contr <- contest(mod, L=c(0,1,0,0,0,0,0,0,0,0,0), joint=FALSE)
        finger.t.stat <- contr$"t value"
        finger.p <- 1- contr$"Pr(>|t|)"

        # foot contrast
        contr <- contest(mod, L=c(0,0,1,0,0,0,0,0,0,0,0), joint=FALSE)
        foot.t.stat <- contr$"t value"
        foot.p <- 1-contr$"Pr(>|t|)"

        # lips contrast
        contr <- contest(mod, L=c(0,0,0,1,0,0,0,0,0,0,0), joint=FALSE)        
        lips.t.stat <- contr$"t value"
        lips.p <- 1-contr$"Pr(>|t|)"

        retvals <- list(finger.t.stat, finger.p, foot.t.stat, foot.p, lips.t.stat, lips.p)
    } else {
        retvals <- rep(999,6)
    }
    names(retvals) <- c("finger.tstat", "finger.p", "foot.tstat", "foot.p", "lips.tstat", "lips.p")
    retvals
}

