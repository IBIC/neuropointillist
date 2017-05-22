# This type of error handling will not always work if run using the parallel library
# It should be run using the --sgeN flag

library(nlme)

processVoxel <-function(v) {
    Y <- voxeldat[,v]
    e <-    try( mod1 <- lme(Y ~ age+ time + domain + target, random=~1+time|idnum, method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
    if (inherits(e, "try-error")) {
            message("error thrown at voxel",v)
            message(e)
            mod1 <- NULL
        }
    e <- try( mod2 <- lme(Y ~ age + time + domain + target + target*domain, random=~1+time|idnum, method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
    if (inherits(e, "try-error")) {
        message("error thrown at voxel",v)
        message(e)
        mod2 <- NULL
    }
    if (!is.null(mod1) & !is.null(mod2)) {
        comparison <- anova(mod1, mod2)
        mod2v1.aic <- comparison$AIC[2]-comparison$AIC[1] 
        mod2v1.bic <- comparison$BIC[2]-comparison$BIC[1] 
        mod2v1.n2ll <- -2*(comparison$logLik[2]-comparison$logLik[1])
        mod2v1.n2llp <- comparison$`p-value`[2]
        mod2.tt <- summary(mod2)$tTable
        mod1.tt <- summary(mod1)$tTable
        retvals <- data.frame(mod2v1.aic,
                      mod2v1.bic,
                      mod2v1.n2ll,
                              mod2v1.n2llp,
                              mod2.tt["time", "p-value"],
                              mod2.tt["age", "p-value"],                        
                              mod2.tt["domain", "p-value"],
                              mod2.tt["target", "p-value"],
                              mod2.tt["domain:target", "p-value"],
                              mod2.tt["time", "t-value"],
                              mod2.tt["age", "t-value"],                              
                              mod2.tt["domain", "t-value"],
                              mod2.tt["target", "t-value"],
                              mod2.tt["domain:target", "t-value"],
                              mod1.tt["time", "p-value"],
                              mod1.tt["age", "p-value"],                              
                              mod1.tt["domain", "p-value"],
                              mod1.tt["target", "p-value"],
                              mod1.tt["time", "t-value"],
                              mod1.tt["age", "t-value"],                        
                              mod1.tt["domain", "t-value"],
                              mod1.tt["target", "t-value"])

    } else {
        retvals <- list(999,999,999,999,999,999,999,999,999,999,999,999,999,999,999,999,999,999,999,999,999,999)
    }
    names(retvals) <- c("dAIC", "dBIC", "LR", "LRp",
                        "mod2time.pvalue", "mod2age.pvalue","mod2domain.pvalue", "mod2target.pvalue", "targetXdomain.pvalue",
                        "mod2time.tvalue", "mod2age.tvalue","mod2domain.tvalue", "mod2target.tvalue", "targetXdomain.tvalue",
                        "mod1time.pvalue", "mod1age.pvalue", "mod1domain.pvalue", "mod1target.pvalue",
                        "mod1time.tvalue", "mod1age.tvalue", "mod1domain.tvalue", "mod1target.tvalue"

                        )                        
    retvals
}
