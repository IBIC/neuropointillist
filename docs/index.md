# Neuropointillist Tutorial

This is a simple tutorial for using neuropointillist to run some examples. This assumes that you have already followed the directions in the Installation section of the README.

## Setting your PATH variable
After you have downloaded and installed the neuropointillist programs in a directory, you need to add this directory to your PATH variable. Suppose that you have downloaded the neuropointillist package into `~/neuropointillist`. Assuming you are running the bash shell, edit your PATH as follows:

`export PATH=$PATH:~/neuropointillist`

This code will make it so that when you type `npoint` or `npointrun` at the command line, your shell can find them. You can put this in your `~/.bashrc` file (if you use bash) so that you don’t have to do this every time you log in.


## fmri Example
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
of 1 in each voxel we will model. There are two sets of input files,
corresponding to time 1 fMRI data and time 2 fMRI data. The input files are all
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

`sim.p-High.gt.Low.nii.gz

sim.tstat-High.gt.Low.nii.gz

sim.tstat-High.nii.gz

sim.tstat-Low.nii.gz`


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
order 1 (AR1).

If the model runs without error, then we compute the p-value of the
contrast (where High > Low).  Variables that we wish to save are collected in a vector, and named. The output variables are assembled into files with the prefix specified by the `--output` flag and the variable names.

For more information on mixed effects modeling of fMRI data in R, see the document "fMRI in R". However, the `processVoxel` function can run any model that can be run on a single voxel. This includes structural equation models, growth models, and so on. This function can also compare several models and output the best according to some criteria. 


### Building models.
When developing your own `processVoxel` function, it is helpful to run interactively on a few specific voxels. Similarly, if there are errors at a voxel it may be helpful to interactively interrogate the model output. The `--debugfile` flag specifies that the design matrix and voxel data should be written to an R file that can be used for model development and debugging.

If you have run `npoint` as directed above, you will have a file called `debug.Rdata` in the `sgedata` directory.

You can start R from within the `sgedata` directory, load this file, and see what is defined.

```R
load(“debug.Rdata”)
ls()
[1] "designmat"          "imagecoordtovertex" "mask.arrayindices" 
[4] "voxeldat"
```

The `designmat` data structure contains the design matrix, and `voxeldat` is a structure that holds all the voxels in the mask. The `imagecoordtovertex` uses the `mask.arrayindices` structure to transform image coordinates to vertex numbers. For example, suppose you want to find the data corresponding to voxel x=20,y=42, z=22 in the `mni_4mm.nii.gz` image. You would call `imagecoordtovertex` as follows.

```R
v <- imagecoordtovertex(20,42,22)
[1] 16733
```

To access the voxel time course (for all subjects and runs) and attach to the design matrix:

```R
attach(designmat)
Y <- voxeldat[,v]
```

## IBIC Internal - Flournoy example
While the code for this example is included in this repository, the data is not released, and is available to people within IBIC.

### Quick start.
Go into the directory `flournoy.example`. 

`cd flournoy.example`

Ask someone where to find the `sfic` directory that has the data you need to run this example (it is not on github). Copy that directory into the `flournoy.example` directory:

`cp -r /path/to/sfic sfic`

Look at the arguments in the file `readargs.R`. Most of these you can leave alone, but look at the option to the `-p` flag. This is 24, which assumes you have 24 processors on your computer. See how many processors you do have:

`nproc`

You should replace 24 with the number of processors on your machine, provided by the `nproc` command, especially if it is less! This flag tells `npoint` to start that many jobs; running more jobs than you have processors can overload your machine.

You need to set an environment variable when using multithreading as above to avoid creating too many threads. If you forget this step, your program might not complete. Do this as follows:

`export OMP_NUM_THREADS=1`

Now run the example. This example is totally canned for you so that it reads all the command line flags from the `readargs.R` file. So all you need to type is

`npoint`

Now wait for a bit. This will take a little time to complete.

When you get your command prompt back, you should have four files in the directory comparemodels:

`fl.dAIC.nii.gz, fl.dBIC.nii.gz, fl.LR.nii.gz and fl.LRp.nii.gz

### What it means.

This is an example of longitudinal fMRI task data from John Flournoy
and Jennifer Pfeiffer. Adolescents were scanned at 3 waves (mean age
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
statistics that are output from a first level analysis.

If you go into the example.flournoy directory, you can see that
setfilenames1.csv contains all the files corresponding to timepoint 1,
setfilenames2.csv has all the files corresponding to timepoint 2, and
setfilenames3.csv has all the files corresponding to
timepoint 3. Similarly, the setlabels1.csv file has a subject id
number, target code, domain code, and time code corresponding to the
information embedded in each of the file names in setfilenames1.csv.

### Covariates. 
The arguments in readargs.R specify that there is a covariates file, Flournoy.new.csv. Covariates are data that are normally per subject/timepoint, or possibly just per subject - they are merged with the collected data across all timepoints, assuming that column headers in the setlabels files are the same things as values in the covariates file. If you look at Flournoy.new.csv you can see that the covariates file includes a subject id number, the time point, age of the subject at that time point, sex, and pubertal development status.

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




