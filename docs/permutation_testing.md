#Overview

The basic steps are:
1. Generate a permutation matrix using the R package `permute`, or your favorite tool.
2. Write a process-voxel function that returns a _Z_-score from a statistical test under the null hypothesis.
3. Run `npoint` to create the permutation job.
4. Transform the permutation-_Z_ maps into `.sdat` format.
5. Run `3dXClustSim` using the _Z_-maps as input.
6. Run `3dMultithres` to apply the Equitable Thresholding and Clustering (ETAC) threshold to the output image for the statistical test from the observed data.

If you're test of interest is simple, afni already has great tools -- for example, `3dttest++`. However, in longitudinal neuroimaging data, more thought must be given to the construction of the permutations as well as the model the best captures the relationship of interest. Here, we will use as an example a 10-wave longitudinal study testing the association between within-person variability in stress and the difference in BOLD signal while viewing fear versus calm faces.

*Some notes before we start:* this requires AFNI version VERSION, as well as a recent installation of Neuropointillist. 

# Generating permutations
It's important to understand the model you want to test, and specifically the null hypothesis of the specific term in the model you want to test. This is because, in complex designs, you must permute the data in a way that respects the structure of the data with regard to the null for the specific regression term you wish to test. For example, we might want to look at the association between a within-person variable and an outcome that varies at the same period. The null hypothesis is that, after controlling for all of the other person-level and time-varying covariates, the association between the target dependent variable and the outcome is no larger than what you might see if randomly ordered that dependent variable. In other words, the null is that you could order the observations within-person willy-nilly, and you'd end up with associations that are about as big as you see when the observations are ordered just as they were collected. If the association is much bigger between the variables ordered just-so and the outcome, then you can decide to reject the hypothesis that the association is just what would be expected from the shuffled data.

There are many different ways of shuffling data within and between grouping-levels, and methods of developing appropriate permutations for this. In our case, we shuffle observations within-person without maintaining their order at all (another method might be to simply shift the observations by some random amount for each person). We don't shuffle observations at all between different participants. 

I say we shuffle observations, but really, what we do in this first step is create a matrix that tells us, for each permutation, how the observations should be ordered. It is thus a $P\times N$ matrix where P is the number of permutations (e.g., 1000) and N is the number of rows in the data. We have 292 observations in these data, so our matrix is $1000\times 292$. Since you've already run the target model, probably, you can simply load the debug data and use that to create your permutation matrix. It's important to be sure that the data set you use to generate permutations is exactly what will be used by the model. This means that any rows that would be automatically dropped by, e.g., `nlme`, should be dropped when generating the permutation matrix. In the code below, I duplicated the model data code from the `processVoxel` function.

```
library(permute)

#This presumes you've arleady set up the target model.
#I load this because it gives us our `ID` variable to
#use in the call to the `permute` functions.
load('/path/to/npoint/model/debug.Rdata')
attach(designmat)
nperm <- 1000 #Make sure this number matches input to NeuroPointillist or is bigger

model_data <- na.omit(data.frame(
  BRAIN = BRAIN, 
  TIMECENTER = TIMECENTER, 
  GCEN_CHRONICAVG = GCEN_CHRONICAVG, 
  WCEN_CHRONICAVG = WCEN_CHRONICAVG, 
  idnum = idnum))

set.seed(1) #Set it to some number for reproducibility
ctrl.free <- how(within = Within(type = 'free'), nperm = nperm, blocks = model_data$idnum)
perm_set.free <- shuffleSet(n = model_data$idnum, control = ctrl.free)
saveRDS(perm_set.free, 'permutation_set-free.RDS')
```

## References

Winkler, A. M., Ridgway, G. R., Webster, M. A., Smith, S. M., & Nichols, T. E. (2014). Permutation inference for the general linear model. _NeuroImage_, _92_, 381–397. [https://doi.org/10.1016/j.neuroimage.2014.01.060](https://doi.org/10.1016/j.neuroimage.2014.01.060)

Winkler, A. M., Webster, M. A., Vidaurre, D., Nichols, T. E., & Smith, S. M. (2015). Multi-level block permutation. _NeuroImage_, _123_, 253–268. [https://doi.org/10.1016/j.neuroimage.2015.05.092](https://doi.org/10.1016/j.neuroimage.2015.05.092)

# processVoxel for permutations

There are many ways of generating permuted test-statistics in data more complex than simple experimental designs in which one can simply permute the labels of conditions. The Freedman and Lane (1983) procedure has been shown to be robust (Anderson & Legendre, 1999). In brief, in order to generate the permutation test-statistic for the *i*th permutation, one does the following:
1) regress the dependent variable (Y) on any covariates, saving the residuals and the predicted values of Y; 
2) permute the residuals according to a row of the permutation matrix, which is then added to the predicted Y values to produce Y*; 
3) regress Y* on the variable of interest, X and covariates, and save the permutation test statistic for the association between X and Y*.

In the example below, we are regressing data from a voxel on a stress measurement that has been decomposed into within-person deviations from between-person, trait-like, components. In the part the implements the Freedman-Lane procedure, I use notation from (Winkler, Ridgway, Webster, Smith, & Nichols, 2014)

```
#Packages:
#  1. nlme for the multi-level model
#  2. clubSandwich for corrected standard errors
#  3. permute just because we're loading a permutation matrix generated by this
#     package
packages <- list('nlme', 'clubSandwich', 'permute')
loaded <- lapply(packages, library, character.only = TRUE)

processVoxel <- function(v) {
  #Load a saved permutation matrix created with the permute package
  permutationRDS = 'permutation_set-free.RDS'
  #Get the permutation vector for this specific permutation. The variable
  #`permutationNumber` is set by Neuropointillist.
  this_perm <- permutationMatrix[permutationNumber, ]
  
  #Set up the data frame for our model, and set a value to return in case the
  #model doesn't converge. These specific variable names are defined in our
  #setlabels file.
  BRAIN <- voxeldat[,v]
  NOVAL <- 999
  model_data <- na.omit(data.frame(
    BRAIN = BRAIN, 
    TIMECENTER = TIMECENTER, 
    GCEN_CHRONICAVG = GCEN_CHRONICAVG, 
    WCEN_CHRONICAVG = WCEN_CHRONICAVG, 
    idnum = idnum))
  
  #Using `try` will prevent crashes due to errors.
  p <- try({
    #We need to capture the residuals (to permute) and predicted values from a
    #model that does not include our variable of interest. See references for
    #more information about this technique.
    residsModel <-
      nlme::lme(BRAIN ~ 1 + TIMECENTER + GCEN_CHRONICAVG,
                random = ~1 | idnum, data = model_data, 
                method = "REML", na.action=na.omit)
    epsilon_z <- resid(residsModel)
    #This is where the permutation vector is used:
    P_j.epsilon_z <- epsilon_z[this_perm]
    Zy <- predict(residsModel, level = 1)
    #Create a new y variable by adding the permuted residuals to the
    #model-predicted y values.
    model_data$y_star <- P_j.epsilon_z + Zy
  })
  
  #Run the full model using the y_star outcome variable as the dependent
  #variable. The test statistic for our variable of interest, `WCEN_CHRONICAVG`
  #in this case, is what we are interested in saving out for the ETAC
  #thresholding.
  e <- try(permutationModel <-
             nlme::lme(y_star ~ 1 + TIMECENTER + GCEN_CHRONICAVG + WCEN_CHRONICAVG,
                       random = ~1 | idnum, data = model_data, 
                       method = "REML", na.action=na.omit) )
  
  #But first, we want to correct the standard error using the sandwich
  #estimator.
  eSandwich <- try(permutationModelSW <- 
                     clubSandwich::coef_test(obj = permutationModel, 
                                             vcov = vcov))
  #If any of the above steps fails, we will return `NOVAL` as the test statistic
  #of interest.
  if (inherits(eSandwich, "try-error")) {
    Z <- NOVAL
  } else {
    #Otherwise, we can transform the corrected t-statistic into a Z-score using
    #the p-value of the t-statistic. AFNI's ETAC software requires the
    #permutation maps be Z-scores.
    Z <- qnorm(pt(permutationModelSW["WCEN_CHRONICAVG", "tstat"], 
                  permutationModelSW["WCEN_CHRONICAVG", "df"]))
  }
  names(Z) <- 'WCEN_CHRONICAVG-z_sw'
  return(Z)
}
```

# Creating ETAC multi-threshold


## Convert to sdat format

After the permutations have run, you'll be left with a number of `nii.gz` files equal to the number of permutations you requested. These must first be transformed into the `sdat` file format either individually, or combined into a single 4D file. To do so, simply run:

```
3dtoXdataset -prefix perm.free.chavg.WCEN_CHRONICAVG-z_sw \
    mask.nii.gz \
    perm.free.chsev.fear.0001WCEN_CHRONICSEV-z_sw.*.nii.gz
```
Note that the sdat format requires you to specify a mask as the first argument to `3dtoXdataset`. The second argument is a list of files to be converted. This command results in a single 4D `sdat` file. 

## Getting the thresholds

Now you can use the `sdat` file to get the multi-thresh file. Bob Cox recommends using the `-global` option and *not* the `-local` option (personal communication). There are many other options one can adjust. See the help file. Below is a basic example command:

```
3dXClustSim -inset mask.nii.gz \
    perm.free.chavg.WCEN_CHRONICAVG-z_sw.sdat \
    -global \
    -prefix perm.free.chavg.WCEN_CHRONICAVG-z_sw.3dXClust
```

This will output three files:
1. globalETAC.mthresh.perm.free.chavg.WCEN_CHRONICAVG-z_sw.3dXClust.A.5perc.niml
2. perm.free.chavg.WCEN_CHRONICAVG-z_sw.3dXClust.mthresh.A.5perc+tlrc.BRIK
3. perm.free.chavg.WCEN_CHRONICAVG-z_sw.3dXClust.mthresh.A.5perc+tlrc.HEAD

The `.niml` file is something that contains the thresholds, and it does not appear this is required for applying the threshold. It's plain text, so feel free to inspect it.

## Applying the thresholds

The `3dMultiThresh` command creates a version of your group-level model that is appropriately thresholded according to the above ETAC mthresh files. In addition to this thresholded map, it may also produce, when passed the `-allmask` option, a multi-volume dataset where each volume is a binary mask of voxels that pass one of the test.

The following code presumes that my group-level model output for the variable of interest is in `chavg.WCEN_CHRONICAVG-t_sw.nii.gz`, and that it has been set up so that AFNI knows that it is a map of *t*-statistics with specific degrees of freedom. It may be simpler to ensure that the group-level map is output in terms of *Z*-scores. It still may be necessary to run, e.g., `3drefit -fizt group_stats_map.nii.gz`.

```
3dMultiThresh -mthresh perm.free.chavg.WCEN_CHRONICAVG-z_sw.3dXClust.mthresh.A.5perc+tlrc \
    -input chavg.WCEN_CHRONICAVG-t_sw.nii.gz \
    -prefix chavg.WCEN_CHRONICAVG-t_sw.multi-threshed.nii.gz \
    -allmask chavg.WCEN_CHRONICAVG-t_sw.multi-threshed.all-mask.nii.gz \
    -nozero
```

The `-nozero` option avoids creating new files if no clusters survive correction.

You are now able to visualize your thresholded statistical map (`chavg.WCEN_CHRONICAVG-t_sw.multi-threshed.nii.gz` in this example) in AFNI or whatever your favorite program is.
<!--stackedit_data:
eyJoaXN0b3J5IjpbOTU1MzkzNDIsLTE3ODAyNTk5MjksODg0Nz
U1MTYzLDgyMzgwNDk4LDIzOTk4ODY5LC0xNzU5NjkzOTQ3LC0x
MTM0OTkwMjIzLC0xNzEyOTYzNDUxLC00MDU3MjA1MjYsLTE3OT
M1MzE3MTJdfQ==
-->
