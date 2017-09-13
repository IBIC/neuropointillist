# This type of error handling will not always work if run using the parallel library
# It should be run using the --sgeN flag

# We need nlme
library(nlme)

processVoxel <-function(v) {
Y <- voxeldat[,v]

# Time as a fixed effect
e <- try(mod.fixedtime <- lme(Y ~ age + domain + target, random=~1|idnum, method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
if (inherits(e, "try-error")) {
   mod.fixedtime <- NULL
}

# Time as a random effect
e <- try(mod.randomtime <- lme(Y ~ age + domain + target, random=list(~1|idnum,~age|idnum), method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
if (inherits(e, "try-error")) {
   mod.randomtime <- NULL
}

# time as random effect and time squared as a fixed effect
# center age
agecenter <- age-mean(age)
# calculate squared centered age
agesqcenter <- agecenter*agecenter

e <- try(mod.timesq <- lme(Y ~ agecenter + agesqcenter + domain + target, random=list(~1|idnum,~agecenter|idnum), method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
if (inherits(e, "try-error")) {
   mod.timesq <- NULL
}


# time as log effect

logage <- log(age)
e <- try(mod.log <- lme(Y ~ logage + domain + target, random=list(~1|idnum,~logage|idnum), method=c("ML"), na.action=na.omit, control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))
if (inherits(e, "try-error")) {
   mod.log <- NULL
}


if (!is.null(mod.fixedtime) && !is.null(mod.randomtime) && !is.null(mod.timesq) && !is.null(mod.log)) {
   mod.fixedtime.tt <- summary(mod.fixedtime)$tTable
   mod.randomtime.tt <- summary(mod.randomtime)$tTable
   mod.timesq.tt <- summary(mod.timesq)$tTable       
#   comp.anova <- anova(mod.fixedtime, mod.randomtime, mod.timesq)
   comp.aic <- AIC(mod.fixedtime, mod.randomtime, mod.timesq, mod.log)
   comp.bic <- BIC(mod.fixedtime, mod.randomtime, mod.timesq, mod.log)   


   retvals <- data.frame(
       mod.fixedtime.tt["age", "p-value"],
       mod.randomtime.tt["age", "p-value"],
       mod.timesq.tt["agecenter", "p-value"],
       mod.timesq.tt["agesqcenter", "p-value"],       
       mod.fixedtime.tt["age", "t-value"],
       mod.randomtime.tt["age", "t-value"],
       mod.timesq.tt["agecenter", "t-value"],
       mod.timesq.tt["agesqcenter", "t-value"],       
        comp.aic["mod.fixedtime", "AIC"],
       comp.aic["mod.randomtime", "AIC"],
       comp.aic["mod.timesq", "AIC"],
       comp.aic["mod.log", "AIC"],       
       comp.bic["mod.fixedtime", "BIC"],
       comp.bic["mod.randomtime", "BIC"],
       comp.bic["mod.timesq", "BIC"],
       comp.bic["mod.log", "BIC"],       
       which.min(comp.bic$BIC),
       which.min(comp.aic$AIC)       
   )

} else {
    retvals <- rep(999,18)

}
names(retvals) <- c("fixedtime.pvalue", "randomtime.pvalue", "timecenter.pvalue", "timecentersq.pvalue",
"fixedtime.tvalue", "randomtime.tvalue", "timecenter.tvalue", "timecentersq.tvalue",                    
                    "aic.fixedtime", "aic.randomtime", "aic.timecentersq", "aic.timelog",
                    "bic.fixedtime", "bic.randomtime", "bic.timecentersq", "bic.timelog", 
                    "bic.best", "aic.best")

retvals
}
    
