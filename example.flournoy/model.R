# This type of error handling will not always work if run using the parallel library
# It should be run using the --sgeN flag

# We need nlme
library(nlme)

processVoxel <-function(v) {
Y <- voxeldat[,v]
tryCatch({
    mod <- lme(Y ~ time + domain + target + target*domain, random=~1+time|idnum, method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE))}, error=function(e){
        message("error thrown at voxel",v)
        message(e)
        return(NULL)})
if (!is.null(mod)) {
    mod.tt <- summary(mod)$tTable
    retvals <- list(mod.tt["time", "p-value"],
                mod.tt["domain", "p-value"],
                mod.tt["target", "p-value"],
                mod.tt["domain:target", "p-value"])
} else {
    retvals <- list(999,999,999,999)
}
names(retvals) <- c("time.pvalue", "domain.pvalue", "target.pvalue", "targetXdomain.pvalue")
retvals
}
    
