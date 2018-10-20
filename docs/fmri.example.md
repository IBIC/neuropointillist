## Simple fMRI Example

### Quick start.

Go into the directory `example.rawfmri`. This example has simulated fMRI data for 8 subjects, two sessions each. 

`cd example.rawfmri`

Look at the arguments in the file `readargs.R`. You don’t need to
change any of these arguments. Options in the file `readargs.R` are read by
`npoint` as a convenience, instead of having to type them all out.


``` R
cmdargs <- c("-m","mask_4mm.nii.gz", "--set1", "setfilenames1.txt",
             "--set2", "setfilenames2.txt",             
             "--setlabels1", "setlabels1.csv",
             "--setlabels2", "setlabels2.csv",             
             "--model", "fmrimodel.R",
             "--output", "sgedata/sim.",
             "--debug", "debug.Rdata",
             "--sgeN", "10")
```

These arguments specify a mask (`mask_4mm.nii.gz`), which has a value
of 1 in each voxel we will model. In the directory, there is also a file called `oneslice_4mm.nii.gz`. If you are on a laptop, or are otherwise very limited in time, you might want to change the mask to be `oneslice_4mm.nii.gz`, which will reduce computation time by limiting analysis to only one slice of the brainmask.

There are two sets of input files, corresponding to time 1 fMRI data and time 2 fMRI data. The input files are all
registered to an MNI template resampled to 4mm isotropic voxels
(`mni_4mm.nii.gz`). If you look at the content of `setfilenames1.txt`
and `setfilenames2.txt` you will see the names of these input files in the
`fmri` subdirectory. Each fMRI file has 150 volumes, and there are 8
subjects at each time point. Therefore, each setlabel file
(`setlabels1.csv` and `setlabels2.csv`) has 8*150=1200 lines. Each
line has two explanatory variables (High and Low), the number of the
volume (TR), the subject number and the number of the time point. The
TR and time point are not used by this model.

To generate the jobs for this example, type:

`npoint`

This program reads in all the fMRI data and splits it up into R jobs
that can be run in parallel. These will be written in the subdirectory
`sgedata`, as specified by the `--output` flag. In this subdirectory
are two scripts of particular interest. The script `runme.local` uses
the UNIX utility `make` to run the model on the machine you are logged
in to. The script `runme.sge` submits the job to the default SGE
cluster using `qsub`. Note that if SGE is not correctly configured,
`runme.sge` will not work.

To run the model on each voxel in the mask, type either:

`runme.local`

or, if you have an SGE cluster

`runme.sge`

When everything has completed, you will have four statistical parameter maps with the results:

* `sim.p-High.gt.Low.nii.gz`

* `sim.tstat-High.gt.Low.nii.gz`

* `sim.tstat-High.nii.gz`

* `sim.tstat-Low.nii.gz`


### What it means.
This is an example on simulated data that runs a mixed effects model on the raw simulated fMRI data. There are two explanatory variables of interest, `High` and `Low`. The file `sim.tstat-High.gt.Low.nii.gz` is a map of the t statistics for the contrast `High > Low`.

To understand this, let us look at the code that actually runs the model, which is in the file `fmrimodel.R`. This is specified using the `--model` flag (in the `readargs.R` file above).

```R
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
```

The `processVoxel` function is run for each voxel number `v`. Thus,
`Y` is the BOLD signal at each voxel. This code specifies a mixed
effects model with two explanatory variables, `High` and `Low`. The
design matrix is made available to the `processVoxel` function
environment. There is a random effect of intercept per subject. We
handle autocorrelation in the model using an autoregressive model of
order 1 (AR1). Note that this may not be adequate for real fMRI data
sets. The point here is not to forget that it is necessary to think
about autocorrelation when you are modeling the raw fMRI time course.

If the model runs without error, then we compute the p-value of the
contrast (where High > Low).  Variables that we wish to save are
collected in a vector, and named. The output variables are assembled
into files with the prefix specified by the `--output` flag and the
variable names.

For more information on mixed effects modeling of fMRI data in R, see
the document [A Tutorial on Modeling fMRI Data Using a General Linear Model](https://psyarxiv.com/crx4m/). 
However, the `processVoxel` function can run
any model that can be run on a single voxel. This includes structural
equation models, growth models, and so on. This function can also
compare several models and output the best according to some criteria.


### Building and debugging models.
When developing your own `processVoxel` function, it is helpful to run interactively on a few specific voxels. Similarly, if there are errors at a voxel it may be helpful to interactively interrogate the model output. The `--debugfile` flag specifies that the design matrix and voxel data should be written to an R file that can be used for model development and debugging.

If you have run `npoint` as directed above, you will have a file called `debug.Rdata` in the `sgedata` directory.

You can start R from within the `sgedata` directory, load this file, and see what is defined.

```R
load(“debug.Rdata”)
ls()
[1] "designmat"          "imagecoordtovertex" "mask.arrayindices" 
[4] "voxeldat"
```

The `designmat` data structure contains the design matrix, and `voxeldat` is a structure that holds all the voxels in the mask. The `imagecoordtovertex` uses the `mask.arrayindices` structure to transform image coordinates to vertex numbers. For example, suppose you want to find the time course corresponding to voxel x=20,y=42, z=22 in the `mni_4mm.nii.gz` image. You would call `imagecoordtovertex` as follows.

```R
v <- imagecoordtovertex(20,42,22)
[1] 16733
```

To access the voxel time course (for all subjects and runs) and attach to the design matrix:

```R
attach(designmat)
Y <- voxeldat[,v]
```
