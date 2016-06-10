# This type of error handling will not always work if run using the parallel library
# It should be run using the --sgeN flag

library(nlme)

processVoxel <-function(v) {
    Y <- voxeldat[,v]
    tryCatch({
        mod1 <- lme(Y ~ age+ time + domain + target, random=~1+time|idnum, method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE))}, error=function(e){
            message("error thrown at voxel",v)
            message(e)
            return(NULL)})
    tryCatch({
        mod2 <- lme(Y ~ age + time + domain + target + target*domain, random=~1+time|idnum, method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE))}, error=function(e){
            message("error thrown at voxel",v)
            message(e)
            return(NULL)})
    if (!is.null(mod1) & !is.null(mod2)) {
        comparison <- anova(mod1, mod2)
        mod2v1.aic <- comparison$AIC[2]-comparison$AIC[1] 
        mod2v1.bic <- comparison$BIC[2]-comparison$BIC[1] 
        mod2v1.n2ll <- -2*(comparison$logLik[2]-comparison$logLik[1])
        mod2v1.n2llp <- comparison$`p-value`[2]
        retvals <- data.frame(mod2v1.aic,
                      mod2v1.bic,
                      mod2v1.n2ll,
                      mod2v1.n2llp)
    } else {
        retvals <- list(999,999,999,999)
    }
    names(retvals) <- c("dAIC", "dBIC", "LR", "LRp")
    retvals
}
