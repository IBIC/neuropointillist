# This model is written so that errors are appropriately trapped and
#handled when running
# using a shared memory multiprocessor
library(lme4)

# Note that lme4 functions do not report p-values. This package incorporates p-values into the output of the functions lmer and anova.
library(lmerTest)

processVoxel <-function(v) {
    BRAIN <- voxeldat[,v]
    e <- try(mod1_crossed <-lmer(BRAIN ~ Finger+Foot+Lips+WhiteMatter+X+Y+Z+RotX+RotY+RotZ + (1 |idnum) + (1|time), REML = FALSE))
    if(inherits(e, "try-error")) {
        mod1_crossed <- NULL
    }

    if(!is.null(mod1_crossed)) {
        # get variance components
        vc <- as.data.frame(VarCorr(mod1_crossed))
        # calculate total random variance not explained by fixed effects
        totalRV <- sum(vc$vcov)
                                        # ICC is the within-subject variance
        ssICC <- vc$vcov[vc$grp=="idnum"]/totalRV
       # ssICC <- vc$vcov[1]/totalRV
        retvals <- list(ssICC)
    } else {
        retvals <- list(999)
    }
    names(retvals) <- c("ICC")
    retvals
}

