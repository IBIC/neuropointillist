## Finger/Foot/Lips Motor Test-Retest Dataset From OpenNeuro
This is an example of running a mixed effects model on preprocessed
fMRI data from a real task. The task is the test-retest dataset for
motor functions, available at
[openneuro](https://openneuro.org/datasets/ds000114/versions/00001)
and described in this
[paper](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3641991/). We are
grateful the authors for making this dataset available in this manner 
to facilitate development of these models.

The motor task is a block design task that consists of blocks of finger tapping, foot twitching, and presumably lip pursing interleaved with visual fixation. There were two occasions of measurement so that test-retest reliability coul be evaluated. 

We include a few examples of different models that one might run. 

*Please Note* All of the readargs files here are configured to generate SGE appropriate output with approximately 50 jobs. On my 28 core machine, this takes about an hour. Please modify the arguments to be appropriate for your environment.

### Quick start.
Go into the directory `example.fingerfootlips`. 

`cd example.fingerfootlips`

You will need to download the data from OpenNeuro. To do this, run 

`./00downloadfiles`

This will create three directories: `fmri`, `confounds`, and
`brainmask`. The `fmri` directory contains fMRI data processed using
[FMRIPREP](https://fmriprep.readthedocs.io/en/stable/). The `00downloadfiles` script removes the first TR, a dummy scan, from these
files. (You can identify the dummy scans because they are bright and have average values much higher than the others).  The `confounds` directory contains the confounds (e.g. motion
parameters, signal from white matter, etc) created by the FMRIPREP
program. Note that we do NOT remove the first TR from these confound files; we
remove it later, when preparing the design matrix. The third directory
`brainmask` contains brain masks for the fMRI data, indicating where
each subject has valid data.

We have created a brain mask for you called `mask.nii.gz` using the
brainmasks in `brainmask`. The script to do this is
`00-Opt-makebrainmask`, which you do NOT need to run. We provide it as
an example for you if you wish to process your own data. It uses FSL
utilities to create a mask which includes only voxels for which every
subject has data.

We have also used FSL to convolve the explanatory variables (provided in `task-fingerfootlips_events.tsv` with a gamma HRF to create task regressors, provided in `task-fingerfootlips_neuropoint.txt`. If you don't use FSL, or if you prefer to convolve with a different function, you could use the `fmri` package from R. 

You can create the setfilenames and the setlabels by running the following scripts:

`./01createSetFilenames`
`./01createSetLabels`

Creation of the set filenames is pretty straightforward; the script just createsa list of the test files as time 1, and the retest files as time 2.  The set labels are created by merging the convolved explanatory variables with the confounds. We also add variables for the subject identifier, the TR, and the time (1 or 2). Finally, we remove the data for the first TR because it is a dummy scan. 


Now run the example. This example is totally canned for you so that it reads all the command line flags from the `readargs.R` file. So all you need to type is

`npoint`

Now wait for a bit. This will take a few minutes to complete. It is
reading in the fMRI files and covariates and splitting up the voxels
in the mask into 50 individual jobs in the directory `sgedata`. This is
useful if your analysis will take a long time, because you can submit
the jobs in a cluster environment.

If you `cd` into the directory `sgedata`, you will see a bunch of
files with the extention `.rds` and `.nii.gz`. The RDS files are data
files, one per each job, that will be read in by R. These contain just
the fMRI data for the voxels in each small chunk of work. The
corresponding NiFTI file is a mask with the spatial information for
where these voxels are located in the brain.

To run the actual analysis will take more time. If you have access to an SGE cluster, you can type:

`runme.sge`

Alternatively, if you are on a multicore Linux or OSX machine, you can type:

`runme.local`

This will run the job on your local machine using 4 cores. 

### What it means.

This is a motor task that involves movement of a finger, foot, and
lips. Different motor tasks activate different areas of the brain.

### Data. 
The data are downloaded from OpenNeuro into the directory `fmri` in the download step described above.

Each file has a name of the following format (* is a wildcard):

`sub-*-test_task*.nii.gz`
or
`sub-*-retest_task*.nii.gz`

There are 10 subjects, numbered 01 through 10. Each subject has a test run and a retest run. For our purposes, we consider the test run to be timepoint 1 and the retest run to be timepoint 2. 

### Confounds.
The fMRI data that we use are pre-processed using FMRIPREP. You can see the description of the confounds in [FMRIPREP documentation] (https://fmriprep.readthedocs.io/en/stable/outputs.html). 

### Model.

The `readargs.R` file specifies that the model we are running in this
example is `nlmemodel.R`. The model code is all that you should ever need
to write. In it, you define a `processVoxel` function that takes a voxel
number (`v`), looks it up in a global data structure (`voxeldat`), and
uses column names of the design matrix (formed from the setlabels and
the covariates) to do some calculation and return statistics.

The model we use tests for where the Beta coefficients of hand, foot
and lips are significantly different from zero, using the `nlme`
package. We include a random effect of intercept, which means we are
not generalizing the Beta coefficients that we estimate to the
population as a whole. Random effects are better expressed using the
`lme4` package. However, the `lme4` package does not allow one to
easily express the autocorrelated structure of the data. With `nlme`,
we can specify an AR(1) model. It is possible, of course, to test whether this removes the autocorrelation structure of the residuals.

Below is a listing of `nlmemodel.R`.

``` R
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


```

### Prewhitening.  
FMRI data is autocorrelated. If we run models with
wild abandon without consideration of the autocorrelation structure of
our data, we will generally get innaccurate results from our statistics. This is something that fMRI software generally does for you, in a process called prewhitening. 

I am not positive what the best way to do prewhitening in
this context should look like. A major goal is to keep the R models
looking fairly simple so that people can read them and understand them
easily. So here we use AFNI to prewhiten the data before modeling.

In the `example.fingerfootlips` directory, run this script:

`03prewhiten`

This takes some time to run and is not parallelized; I suggest starting it before you leave for the day. This will create the directory `fmri.prewhiten`. Data
here are prewhitened using AFNI `3dREMLfit` with a default column matrix of 1s as described [in this posting](https://afni.nimh.nih.gov/afni/community/board/read.php?1,84268,158612#msg-158612). There may be better ways to do this; for example, see the procedure that
[Mandy Mejia recommends](https://mandymejia.wordpress.com/2016/11/06/how-to-efficiently-prewhiten-fmri-timeseries-the-right-way/). 

However, the data created in `fmri.prewhiten` are used in subsequent models to produce what I think should be more realistic parameter estimates.

### Using lme4.
This example uses the `lmer` function from the `lme4` library to do the same analysis as above. However, this model uses prewhitened data and accurately models random slopes, so it is the closest approximation to what FSL and other packages do. 

Note that `lmer` does not generate p statistics. They are provided by
the library `lmerTest`, which overrides the `lmer` command and
provides the `contest` function to evaluate the significance of
contrasts.

To run this example, link the file `readargs.lmermodel.prewhitened.R` to be just `readargs.R`:

`bash
rm readargs.R
ln -s readargs.lmermodel.prewhitened.R readargs.R
`
If you run `npoint`, this  will create the output directory lmer.prewhitened. As always, go into that directory and execute the appropriate run script for your environment. If you are curious, there is also an argument file called `readargs.lmermodel.notprewhitened.R` that you could run for comparison, to see the difference that prewhitening makes.

The model is listed below.

```r

library(lme4)

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

```

## An Intraclass Correlation.

This is an example that calculates the ICC as the within-subject variance divided by the total variance. Note that this example illustrates one of the 

```r
library(lme4)

library(lmerTest)

processVoxel <-function(v) {
    BRAIN <- voxeldat[,v]
    e <- try(mod1_crossed <-lmer(BRAIN ~ Finger+Foot+Lips+WhiteMatter+X+Y+Z+RotX+RotY+RotZ + (1 + Finger+Foot+Lips|idnum) + (1|time), REML = FALSE))
    if(inherits(e, "try-error")) {
        mod1_crossed <- NULL
    }

    if(!is.null(mod1_crossed)) {
        # get variance components
        vc <- as.data.frame(VarCorr(mod1_crossed))
        # calculate total random variance not explained by fixed effects
        totalRV <- sum(vc$vcov)
        # ICC is the within-subject variance
        ssICC <- vc$vcov[1]/totalRV
        retvals <- list(ssICC)
    } else {
        retvals <- list(999)
    }
    names(retvals) <- c("ICC")
    retvals
}

```
