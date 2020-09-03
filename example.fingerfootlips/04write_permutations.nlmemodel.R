#!/usr/bin/env Rscript
#You can install the permute package by running:
# install.packages('permute')
library(permute)

message('Loading data...')

#You must have already set up the target model so we can work with the debug
#data (as specified in the readargs.R file)

#The next line presumes you've set your working directory to the directory from
#which you ran `npoint` to generate the target model.
if(!file.exists('nlmemodel/debug.Rdata')){
  stop('nlmemodel/debug.Rdata does not exist. Have you run the target model?')
} else {
  load('nlmemodel/debug.Rdata')  
}


#We attach the design matrix to access the variables our processVoxel function
#will have access to.
attach(designmat)

#The next line sets the number of permutations. Make sure this number matches
#input you will pass to Neuroointillist. If you're using a random subset of
#permutations, this number can be bigger than what you ultimately pass to
#Neuropointillist. It doesn't hurt to have some extras.
nperm <- 1000 

#In order to generate permutations that will be accurately used in the
#permutation model, we must ensure our data set-up is identical to the target
#model. In the case of the nlmemodel.R model, there is no preprocessing of the
#data, so we can use the raw `idnum` variable in order to generate the correct
#permutation patterns.

set.seed(2322) #for reproducibility
message('Generating ', nperm, ' permutations...')

#We will shuffle _within person_ because under the null hypothesis, if a
#particular movement has no effect on brain function, then every TR should be
#more or less like every other TR (after we account for autocorrelation). Note
#that this is _just an example_ and in practice you should give a lot of thought
#to how your permutations are set up with respect to the data structure and your
#null hypothesis.
#
#To learn more about developing appropriate permutation matrices for complex
#designs, see Winkler et al. (2014).
#
#The `permute` package makes it easy to shuffle blocks of data, and
#within-blocks, depending on your situation. It also alows you to account for
#time-series structures like we have here using the 'series' option. We can also
#ensure that we don't permute across time-points by using that as a 'block'
#which cannot be permuted at all.

#Winkler, A. M., Ridgway, G. R., Webster, M. A., Smith, S. M., & Nichols, T. E.
#(2014). Permutation inference for the general linear model. NeuroImage, 92,
#381–397. https://doi.org/10.1016/j.neuroimage.2014.01.060

ctrl.free <- how(within = Within(type = 'series'), 
                 plots = Plots(strata = idnum, type = 'none'), 
                 blocks = time,
                 nperm = nperm)
#This creates the permutation matrix (P permutations x N rows of the desing matrix)
perm_set <- shuffleSet(n = idnum, control = ctrl.free)

#Here we save this to an RDS file that we can access in our processVoxel
#function. We'll create a new directory for all the rest of our permutation
#stuff to go in.
permpath <- file.path('permutations.RDS')
message('Saving permutations to ', permpath)
saveRDS(perm_set, permpath)

message('Please copy file readargs.nlmemodel.permute.R to readargs.R and then run `npoint` to generate files necessary to run permutations.')
