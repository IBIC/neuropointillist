# Permutation testing using Finger, Foot, Lips data

This assumes that you have completed the finger-foot-lips example
using the `nlmemodel.R` model. You should have a directory called
`nlmemodel/` with a `debug.Rdata` file, p-value maps, and t-score maps
for the finger, foot, and lips contrasts.


Here is an overview of the steps needed after fitting the model of interest :

1. Generate a permutation matrix using the R package `permute`, or your favorite tool (ensure that it respects your data structure and statistical question).

2. Write a `processVoxel` function that returns a _Z_-score from the statistical test used for the model of interest.

3. Compose the `readargs.R` file to use the permutation feature of Neuropointillist, and make sure the base directory has all the necessary files (at the moment, you have to copy the permutation matrix RDS file there).

4. Run `npoint` to create the permutation job.

5. Compose a batch script appropriate for your scheduler (we will use a SLURM batch in this example).

6. Run the N permutation jobs (this may take a little while).

To use AFNI's Equitable Thresholding and Clustering (ETAC) method for
cluster correction, follow these additional steps:

1. Merge the permutation-_Z_ maps into `.sdat` format.
9. Run `3dXClustSim` using the _Z_-maps as input.
10. Run `3dMultithresh` to apply the ETAC threshold to the output image for the statistical test from the observed data.

_Caveat:_ If your test of interest is simple, AFNI already has great
tools that implement permutation testing---for example,
`3dttest++`. FSL's randomise can handle nested data for almost any
design you can generate with FEAT, which may include some
repeated-measures designs.

In longitudinal neuroimaging, the model that best captures the relationship of interest may not be one supported by existing software. In this case, you can use Neuropointillist to construct the model of interest and an appropriate permutation testing scheme.


## Generating permutations
It's important to understand the model you want to test, and specifically the null hypothesis of the specific term in the model you want to test. This is because, in complex designs, you must permute the data in a way that respects the structure of the data with regard to the null for the specific regression term you wish to test. For example, we might want to look at the association between a within-person variable and an outcome that varies at the same period. The null hypothesis is that, after controlling for all of the other person-level and time-varying covariates, the association between the target dependent variable and the outcome is no larger than what you might see if randomly ordered that dependent variable. In other words, the null is that you could order the observations within-person willy-nilly, and you'd end up with associations that are about as big as you see when the observations are ordered just as they were collected. If the association is much bigger between the outcome and the predictor variable observations ordered just-so, then you can decide to reject the null hypothesis.

There are many different ways of shuffling data within and between grouping-levels (exchangeability blocks; Winkler et al, 2014), and methods of developing appropriate permutations for this. In the finger-foot-lips example, I will shuffle observations within-person by shifting the observations by some random amount for each person, per permutation (this maintains the strongly autocorrelated structure of the data). I don't shuffle observations at all between different participants, or between different runs, though you might have some reason to do so. 

I say we shuffle observations, but really, what we do in this first step is create a matrix that tells us, for each permutation, how the observations should be ordered. It is thus a P*N matrix where P is the number of permutations (e.g., 1000) and N is the number of rows in the data. We have  observations in these data, so our matrix is 1000 * 3660. Since you've already run the target model you can simply load the debug data and use that to create your permutation matrix. It's important to be sure that the data set you use to generate permutations is exactly what will be used by the model. This means that any rows that would be automatically dropped by, e.g., `nlme`, should be dropped when generating the permutation matrix. Here's the code I've used to generate the permutation matrix:

```
#!/usr/bin/env Rscript
library(permute)

if(!file.exists('nlmemodel/debug.Rdata')){
  stop('nlmemodel/debug.Rdata does not exist. Have you run the target model?')
} else {
  load('nlmemodel/debug.Rdata')  
}

attach(designmat)
nperm <- 1000 
set.seed(2322) #for reproducibility

ctrl.free <- how(within = Within(type = 'series'), 
                 plots = Plots(strata = idnum, type = 'none'), 
                 blocks = time,
                 nperm = nperm)
perm_set <- shuffleSet(n = idnum, control = ctrl.free)

permpath <- file.path('permutations.RDS')
saveRDS(perm_set, permpath)
```

A much more well commented version of this code is in the `example.fingerfootlips` directory. Run this as follows.

```bash
./04write_permutations.nlmemodel.R
```

This script outputs a single file called `permutations.RDS` which needs to be copied into the permutation base directory once we've created it. But first we need to write the processVoxel funciton.

## processVoxel for permutations

This processVoxel function will be run once for every voxel, for every permutation. The voxel is indexed with variable `v` and the permutation with `permutationNumber`. We want it to return a single value that is the test statistic estimated on data constructed so the null hypothesis is true. We will focus on the contrast for finger tapping.

There are many ways of generating permuted test-statistics in data more complex than simple experimental designs in which one can simply permute the labels of conditions. There are also different ways one can account for covariates (and not accounting for covariates leads to erroneous results). The Freedman and Lane (1983) procedure has been shown to be a robust method of accounting for covariates and applying a permutation matrix to data  (Anderson & Legendre, 1999). This procedure, in brief, generates the permutation test-statistic for the *i*th permutation using the following steps:

1) Regress the dependent variable (Y) on any covariates (but not the variable of interest), saving the residuals and the predicted values of Y.
2) Permute the residuals according to a row of the permutation matrix; add the permuted residuals to the model-predicted Y values to produce Y*.
3) Regress Y* on the variable of interest, X, and covariates; save the permutation test statistic for the association between X and Y*.

In the example below, we are regressing data from a voxel on a the convolved event impulses for the finger, foot, and lips task, as well as several covariates. In the part the implements the Freedman-Lane procedure, I use notation from Winkler et al (2014). _Note well:_ the variable `permutationNumber` is supplied by Neuropointillist, so don't worry that it is never defined; we will use it to pick out the correct row of the permutation matrix.

You can find the below code with additional comments in `example.fingerfootlips/nlmemodel.permute.R`.

```
library(nlme)

#The code here makes it easy to test the function (uncomment and run 
#these lines, and then you can run what is inside the function):
#
#load('nlmemodel/debug.Rdata')
#attach(designmat)
#v <- 1e5
#permutationNumber <- 1

processVoxel <-function(v) {
  #Get the brain data from voxel `v`
  BRAIN <- voxeldat[,v]
  
  #Load the permutation matrix. `permutationNumber` is supplied by neuropointillist.
  permutationMatrix <- readRDS('permutations.RDS')
  ithPermutation <- permutationMatrix[permutationNumber, ]
  
  #To implement Freedman-Lane we first estimate the model without the target
  #effect, extract the residuals, permute them, and add them to the
  #model-predicted y values; this new vector, y_star, then becomes the outcome
  #variable for our effect of interest (Winkler, 2014).

  #First, fit the residuals model and create Y*
  p <- try({
    #exclude `finger` since that's what we want to generate null data for
    residsModel <- nlme::lme(BRAIN ~ 1 + Foot + Lips + WhiteMatter + X + Y + Z + RotX + RotY + RotZ, 
                             random = ~1 | idnum, 
                             method = c("ML"), 
                             na.action = na.omit, 
                             corr = corAR1(form = ~ 1 | idnum), 
                             control = lmeControl(returnObject = TRUE, singular.ok = TRUE))
    
    #get the residuals from the model without `finger`---in other words, get
    #all the variability that can't be explained by the covariates.
    epsilon_z <- resid(residsModel, level = 1)
    
    #permute these residuals according the the scheme we established previously
    #and loaded from the RDS file.
    P_j.epsilon_z <- epsilon_z[ithPermutation]
    
    #get the model-expected y values from the covariates-only model
    Zy <- predict(residsModel, level = 1)
    
    #compose our new y_star variable from the permuted residuals and the model
    #predicted y values. Now we have a variable where the variance not explained
    #by the covariates is, by construction, random with respect to the
    #predictor, while we also retain all of the variance that is systematically
    #related to the covariates.
    y_star <- P_j.epsilon_z + Zy
    #return the model
    residsModel
  })
  
  #Target model using the permuted data
  e <- try(mod <- lme(y_star ~ 1 + Finger + Foot + Lips + WhiteMatter + X + Y + Z + RotX + RotY + RotZ, 
                      random = ~ 1 | idnum, 
                      method = c("ML"), 
                      na.action = na.omit, 
                      corr = corAR1(form = ~ 1 | idnum), 
                      control = lmeControl(returnObject = TRUE, singular.ok = TRUE)))
  
  if(inherits(e, "try-error")) {
    mod <- NULL
  }
  if(!is.null(mod)) {
    #We want to return the Z score that corresponds to the p-value of the
    #statistic we're interested in. To do so we compute the contrast for the
    #Finger condition (there are also other ways to get these values):
    #
    #          1 + Finger + Foot + Lips + WhiteMatter + X + Y + Z + RotX + RotY + RotZ
    contr <- c(0,       1,     0,     0,            0,  0,  0,  0,     0,     0,     0)
    out <- anova(mod, L = contr)
    finger.p <- out[["p-value"]]
    finger.Z <- qnorm(finger.p)
    
    retvals <- c(finger.Z)
  } else {
    # If we are returning 4 dimensional data, we need to be specify how long
    # the array will be in case of errors
    retvals <- c(NULL)
  }
  names(retvals) <- c("finger-Z")
  return(retvals)
}
```

The code above is very similar to the `processVoxel` function for the target model. In fact, except for the permutation steps, it should be essentially identical. The one major difference is that we only return a single statistic.

## Using Neuropointillist

Almost all of the pieces are in place to run Neuropointillist. The final steps are to create a `readargs.R` file, run `npoint`, and copy `permutations.RDS`to the permutations base directory.

To follow the example, first create the `readargs.R` file. Let's also copy a smaller mask into this directory and replace the full mask with this smaller mask to run this more quickly. Note that the original file that uses the full mask can be found in `readargs.nlmemode.permute.R`.

```bash
cp ../example.rawfmri/smallermask.nii.gz .
cat > readargs.R << EOF
cmdargs <- c("-m","smallermask.nii.gz", 
             "--set1", "setfilenames1.txt",
             "--set2", "setfilenames2.txt",             
             "--setlabels1", "setlabels1.csv",
             "--setlabels2", "setlabels2.csv", 
             "--model", "nlmemodel.permute.R",
             "--testvoxel", "500",
             "--output", "nlmemodel.perms/n.p.",
             "--debugfile", "debug.Rdata",
             "--slurmN", "1", #This is ignored
             "--permute", "1000")
EOF
```
Next run `npoint` which creates the base directory, `nlmemodel.perms`,  and tests the model.

```bash
npoint
```

Now, copy our permutations into this new directory.
```bash
cp permutations.RDS nlmemodel.perms
```

We need to create a slurm job script, because permutation testing is life at the bleeding edge.

```bash
cat > permutations.slurm.sh << 'EOF'
#!/bin/bash
#Slurm submission options
#SBATCH -o npointperm_%A_%a.out
#SBATCH --mail-type=END


export OMP_NUM_THREADS=1

#You shouldn't need to edit below this
num=$(printf "%04d" $SLURM_ARRAY_TASK_ID)
dashm="n.p.0001.nii.gz"
model="$(pwd -P)/nlmemodel.permute.R"
permfile="finger-Z.${num}permute.nii.gz"
design="n.p.designmat.rds"

echo running: srun -c 1 /usr/bin/time --verbose npointrun -m ${dashm} --model ${model} --permutationfile ${permfile} -d "${design}"

srun -c 1 /usr/bin/time --verbose npointrun -m ${dashm} --model ${model} --permutationfile ${permfile} -d ${design}
EOF
``` 

Now submit the slurm job.

```bash
sbatch --array=1-1000 permutations.slurm.sh
```

When this completes, we'll be left with 1,000 files called `n.p.0001finger-Z.NNNN.nii.gz`, where NNNN is an index from 0001-1000. 


## Creating ETAC multi-threshold


### Convert to sdat format

After the permutations have run, you'll be left with a number of `nii.gz` files equal to the number of permutations you requested. These must first be transformed into the `sdat` file format either individually, or combined into a single 4D file. To do so, simply run:

```bash
3dtoXdataset -prefix n.p.0001finger-Z \
    ../smallermask.nii.gz \
    n.p.0001finger-Z.*.nii.gz
```
Note that the sdat format requires you to specify a mask as the first argument to `3dtoXdataset`. The second argument is a list of files to be converted. This command results in a single 4D `sdat` file. 

### Getting the thresholds

Now you can use the `sdat` file to get the multi-thresh file. Bob Cox recommends using the `-global` option and *not* the `-local` option (personal communication). There are many other options one can adjust. See the help file. Below is a basic example command (be sure to set the environment variable to use the number of CPU cores available to you, the more the better):

```bash
export OMP_NUM_THREADS="1" #increase as much as you can
3dXClustSim -inset smallermask.nii.gz \
    n.p.0001finger-Z.sdat \
    -global \
    -prefix n.p.0001finger-Z.3dXClust
```

This will output three files:

1. globalETAC.mthresh.n.p.0001finger-Z.3dXClust.A.5perc.niml
2. n.p.0001finger-Z.3dXClust.mthresh.A.5perc+orig.BRIK
3. n.p.0001finger-Z.3dXClustmthresh.A.5perc+orig.HEAD

The `.niml` file is something that contains the thresholds, and it does not appear this is required for applying the threshold. It's plain text, so feel free to inspect it.

### Applying the thresholds

The `3dMultiThresh` command creates a version of your group-level model that is appropriately thresholded according to the above ETAC mthresh files. In addition to this thresholded map, it may also produce, when passed the `-allmask` option, a multi-volume dataset where each volume is a binary mask of voxels that pass one of the tests.

The following code presumes that the group-level model output for the variable of interest is a file called `../nlmemodel/n.finger.tstat.nii.gz`, and that it has been set up so that AFNI knows that it is a map of *t*-statistics with specific degrees of freedom. It may be simpler to ensure that the group-level map is output in terms of *Z*-scores. It still may be necessary to run, e.g., `3drefit -fizt group_stats_map.nii.gz`.

_Note:_ I set `-prefix` and `-allmask` below to create the new files in the directory of the target model, `../nlmemodel/`.

```bash
3dMultiThresh -mthresh n.p.0001finger-Z.3dXClust.mthresh.A.5perc+orig \
    -input ../nlmemodel/n.finger.tstat.nii.gz \
    -prefix ../nlmemodel/n.finger.tstat.multi-threshed.nii.gz \
    -allmask ../nlmemodel/n.finger.tstat.multi-threshed.all-mask.nii.gz \
    -nozero
```

The `-nozero` option avoids creating new files if no clusters survive correction.

You are now able to visualize your thresholded statistical map (`n.finger.tstat.multi-threshed.nii.gz` in this example) in AFNI or whatever your favorite program is. If you do want to use AFNI, it helps to have a standard anatomical map for use as an underlay. You can copy one from FSL by executing `cp  $AFNI_HOME/MNI_avg152T1+tlrc* ./`. It can also be helpful to set the space for the multi-threshed images so that AFNI knows it can overlay it on a standard anatomical map. Do so by running `3drefit -view tlrc -space MNI n.finger.tstat.multi-threshed.*nii.gz` in whatever directory you saved those files.

## References

Anderson, M. J., & Legendre, P. (1999). An empirical comparison of permutation methods for tests of partial regression coefficients in a linear model. Journal of Statistical Computation and Simulation, 62(3), 271–303. https://doi.org/10.1080/00949659908811936

Freedman, D., & Lane, D. (1983). A Nonstochastic Interpretation of Reported Significance Levels. Journal of Business & Economic Statistics, 1(4), 292–298. JSTOR. https://doi.org/10.2307/1391660

Winkler, A. M., Ridgway, G. R., Webster, M. A., Smith, S. M., & Nichols, T. E. (2014). Permutation inference for the general linear model. NeuroImage, 92, 381–397. https://doi.org/10.1016/j.neuroimage.2014.01.060



