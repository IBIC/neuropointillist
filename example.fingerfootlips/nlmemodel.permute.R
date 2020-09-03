#This model uses a previously written permutation matrix and the permutation
#functionality of Neuropointillist to generate a large number of volumes
#containing statistics of interested estimated on data that has been constructed
#such that the null hypothesis is true.
#
#Crucially, certain aspects of correction for covariates during the permutation
#process require that we produce a _separate permutation for each statistic of
#interest_. For that reason we will only generate the permuted data for the test
#of the finger contrast.
#
#In order to correctly account for the possibly non-null effect of covariates
#(and other task events) and isolate the effect of interest. We will implement
#the Freedman-Lane procedures (Freedman and Lane, 1983) to account for
#covariates properly.
#
#Our goal is to output a Z statistic that represents evidence against the null
#hypothesis. We will do this by transforming the p-value of the t-statistc.

#Freedman, D., & Lane, D. (1983). A Nonstochastic Interpretation of Reported
#Significance Levels. Journal of Business & Economic Statistics, 1(4), 292–298.
#https://doi.org/10.2307/1391660

library(nlme)

#
#load('nlmemodel/debug.Rdata')
#attach(designmat)
#

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
  
  #Winkler, A. M., Ridgway, G. R., Webster, M. A., Smith, S. M., & Nichols, T. E.
  #(2014). Permutation inference for the general linear model. NeuroImage, 92,
  #381–397. https://doi.org/10.1016/j.neuroimage.2014.01.060
  p <- try({
    #exclude `finger` since that's what we want to generate null data for
    residsModel <- nlme::lme(BRAIN ~ 1 + Foot + Lips + WhiteMatter + X + Y + Z + RotX + RotY + RotZ, 
                             random = ~1 | idnum, 
                             method = c("ML"), 
                             na.action = na.omit, 
                             corr = corAR1(form = ~ 1 | idnum), 
                             control = lmeControl(returnObject = TRUE, singular.ok = TRUE))
    
    #get the residuals from the model without `finger` -- in other words, get
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
    residsModel
  })
  
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
    contr <- c(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0)
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

