## Flournoy example (longitudinal)
While the code for this example is included in this repository, the data is not released, and is available to people within IBIC. If you are not able to access the data, you can download a simulated data set with the same file structure from the [Neuropointillist example data](https://osf.io/kqtj7/files/) repository on OSF (the zip file is roughly 700 MB). This is a longitudinal example using the parameter estimates from first level analyses using standard fMRI software. 

### Quick start.

If you downloaded a zip file with the simulated SFIC data from OSF, unzip that file and note the location of the directory. It will probably be called `sfic`.

Go into the directory `example.flournoy`. 

`cd example.flournoy`

Copy the directory with the real or simulated SFIC data files to the into the `example.flournoy` directory:

`cp -r /path/to/sfic sfic`

Look at the arguments in the file `readargs.R`. Most of these you can leave alone, but look at the option to the `-p` flag. This is 24, which assumes you have 24 processors on your computer. See how many processors you do have:

`nproc`

You should replace 24 with the number of processors on your machine, provided by the `nproc` command, especially if it is less! This flag tells `npoint` to start that many jobs; running more jobs than you have processors can overload your machine.

You need to set an environment variable when using multithreading as above to avoid creating too many threads. If you forget this step, your program might not complete. Do this as follows:

`export OMP_NUM_THREADS=1`

Now run the example. This example is totally canned for you so that it reads all the command line flags from the `readargs.R` file. So all you need to type is

`npoint`

Now wait for a bit. This will take a little time to complete.

When you get your command prompt back, you should have four files (in addition to others) in the directory `comparemodels`:

* `fl.dAIC.nii.gz`
* `fl.dBIC.nii.gz`
* `fl.LR.nii.gz`
* `fl.LRp.nii.gz`

### What it means.

This is an example of longitudinal fMRI task data from John Flournoy
and Jennifer Pfeifer. Adolescents were scanned at 3 waves (mean age
10, 13, and 16) while making evaluations of self and other in the
social and academic domains. The “other” target was a fictional
character, Harry Potter, about whom participants all had substantial
knowledge. An equal number of items were positive and negative. Sample
phrases included “I am popular”, “I wish I had more friends”, “I like
to read just for fun,” and “Writing is so boring”.  Thus, the goal was
to look at activation related to self and other in different domains
throughout adolescent development.

### Data. 
The data are in a directory called `sfic` (this is not on github - you need to find it elsewhere). Each file has a name of the following format (question marks are wildcards):

`s???_t?_con_????.nii`

Let’s break this down:
* `s???` is the subject id
* `t?` is the timepoint (1-3)
* `con_???` indicates the contrast (1-4)

The contrasts 1-4 correspond to TargetXDomain (1= SelfXAcademic,
2=SelfXSocial, 3=OtherXAcademic, and 4=OtherXSocial). These are the
statistics that are output from a first level analysis using dedicated fMRI analysis software.

If you go into the `example.flournoy` directory, you can see that
`setfilenames1.csv` contains all the files corresponding to timepoint 1,
`setfilenames2.csv` has all the files corresponding to timepoint 2, and
`setfilenames3.csv` has all the files corresponding to
timepoint 3. Similarly, the `setlabels1.csv` file has a subject id
number, target code, domain code, and time code corresponding to the
information embedded in each of the file names in `setfilenames1.csv`.

### Covariates. 
The arguments in readargs.R specify that there is a covariates file, `Flournoy.csv`. Covariates are data that are normally per subject/timepoint, or possibly just per subject - they are merged with the collected data across all timepoints, assuming that column headers in the setlabels files are the same things as values in the covariates file. If you look at `Flournoy.new.csv` you can see that the covariates file includes a subject id number, the time point, age of the subject at that time point, sex, and pubertal development status.

### Model.

The `readargs.R` file specifies that the model we are running in this
example is `model2.R`. The model code is all that you should ever need
to write. In it, you define a `processVoxel` function that takes a voxel
number (`v`), looks it up in a global data structure (`voxeldat`), and
uses column names of the design matrix (formed from the setlabels and
the covariates) to do some calculation and return statistics.

If you take a look at this particular model code, you can see that
this code tests two linear models (`mod1` and `mod2`). The second model
includes a term that tests whether there is an interaction between the
target and the domain. The two models are compared and we output (in
retvals) a list of model fit statistics. The names of these retvals
are used to create output file names.

Thus, the purpose of this model is to compare two specific models and output voxelwise fit statistics. 

Below is a listing of `model2.R`.

``` R
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
```


### Lavaan example (SEM parallel growth).
Using the same data set as above, you can see how one might implement a parallel growth model with the R package `lavaan`. An example model is in `example.lavaan`.

``` R
library(lavaan)
library(tidyr)
processVoxel <- function(v) {
    Y <- voxeldat[,v]
    adf <- data.frame(idnum,sex,pds,age,time,target,domain,Y)
    data <- aggregate(adf, by=list(adf$idnum, adf$time),FUN=mean)
    data$idnum <- data$Group.1

    adf <- data
    adf <- adf[,c("idnum", "sex", "pds", "age", "time", "Y")]
    colnames(adf) <-c("idnum", "sex", "pds", "age", "time", "Y")


#widen the data for lavaan
adf_w <- adf[, grep('age', names(adf), invert = T)] %>% 
  gather(variable, value, pds, Y) %>%
  unite(var_time, variable, time) %>%
  spread(var_time, value)

#head(adf_w)

require(lavaan)

cor_lgc_model <- '
#centered at wave 2, time unit = years
Y_i =~ 1*Y_0 + 1*Y_1 + 1*Y_2
Y_s =~ -3*Y_0 + 0*Y_1 + 3*Y_2
pds_i =~ 1*pds_0 + 1*pds_1 + 1*pds_2
pds_s =~ -3*pds_0 + 0*pds_1 + 3*pds_2

#correlations explicitly coded, but would be generated by default
Y_i ~~ Y_s + pds_i + pds_s
Y_s ~~ pds_i + pds_s
pds_i ~~ pds_s
Y_s~~0*Y_s
'

e <- try(fit <- lavaan::growth(cor_lgc_model, data = adf_w, missing="fiml",standardized=TRUE))

if(inherits(e,"try-error")) {
            message("error thrown at voxel",v)
            message(e)
            fit <- NULL
        }

    if (!is.null(fit)) {
        unstd_ests <- parameterEstimates(fit)
        vars <- subset(unstd_ests, op=="~~" & lhs==rhs)
        if (sum(vars$est < 0) > 1) { #negative variances, abort!
            fit <- NULL
        }
    }

#summary(fit)
    if (!is.null(fit)) {
        unstd_ests <- parameterEstimates(fit)
        param_ests <- standardizedsolution(fit)
        param_ests$name <- paste(param_ests$lhs, param_ests$op, param_ests$rhs,sep="")
  # get p values from unstandardized
        param_ests$pvalue <- unstd_ests$pvalue
                                        # get fit measures
        fit <- fitmeasures(fit, c("rmsea", "cfi", "pvalue"))


        latent_int <- param_ests[param_ests$lhs %in% c('Y_i', 'Y_s', 'pds_i', 'pds_s') & 
                                     param_ests$op %in% c('~1'),]
        latent_varcov <- param_ests[param_ests$lhs %in% c('Y_i', 'Y_s', 'pds_i', 'pds_s') & 
                                        param_ests$op %in% c('~~'),]

        ret <- rbind(latent_int, latent_varcov)

# make sure order is correct
        ret <- ret[order(ret$name),]

        retvals <- c(ret$est.std,ret$pvalue, fit)

        names(retvals) <-c(paste(ret$name,".est",sep=""), paste(ret$name, ".pvalue", sep=""), "rmsea", "cfi", "chisq.pvalue")

    } else {
        retvals <- rep(-999, 31)
        names(retvals) <- c(
"pds_i~1.est",         "pds_i~~pds_i.est",    "pds_i~~pds_s.est",
 "pds_s~1.est",         "pds_s~~pds_s.est",    "Y_i~1.est",
 "Y_i~~pds_i.est",      "Y_i~~pds_s.est",      "Y_i~~Y_i.est",
 "Y_i~~Y_s.est",        "Y_s~1.est",           "Y_s~~pds_i.est",    
 "Y_s~~pds_s.est",      "Y_s~~Y_s.est",        "pds_i~1.pvalue",    
 "pds_i~~pds_i.pvalue", "pds_i~~pds_s.pvalue", "pds_s~1.pvalue",    
 "pds_s~~pds_s.pvalue", "Y_i~1.pvalue",        "Y_i~~pds_i.pvalue",
 "Y_i~~pds_s.pvalue",   "Y_i~~Y_i.pvalue",     "Y_i~~Y_s.pvalue", 
 "Y_s~1.pvalue",        "Y_s~~pds_i.pvalue",   "Y_s~~pds_s.pvalue",
 "Y_s~~Y_s.pvalue",     "rmsea",               "cfi",
 "chisq.pvalue")     
}
retvals
}

```





