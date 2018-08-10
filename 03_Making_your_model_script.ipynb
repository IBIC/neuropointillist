{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Making your model script\n",
    "\n",
    "Adapted from http://ibic.github.io/neuropointillist/ and http://ibic.github.io/neuropointillist/usage.html\n",
    "\n",
    "In this tutorial, we will use the provided `example.rawfmri` dataset to breakdown the mixed model script, fmrimodel.R, called in neuropointillist.\n",
    "\n",
    "While the neuropointillist code is mostly in R, you will interact with its functions through the terminal using Bash."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "This is an example on simulated data that runs a mixed effects model on the raw simulated fMRI data. There are two explanatory variables of interest, `High` and `Low`. As in traditional fMRI GLM analyses, the response variable, `Y`, is the voxel values.The file `sim.tstat-High.gt.Low.nii.gz` is a map of the t statistics for the contrast `High > Low`. "
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "The dataframe will look like this:"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "\n",
    "            High     Low    TR subject  time\n",
    "        1 -0.401 -0.399      1       1     1\n",
    "        2 -0.401 -0.296      2       1     1\n",
    "        3 -0.401  0.0660     3       1     1\n",
    "        4 -0.401  0.442      4       1     1\n",
    "        5 -0.401  0.659      5       1     1\n",
    "        6 -0.401  0.737      6       1     1"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "Let's look at the code that actually runs the model, which is in the file `fmrimodel.R`. This is specified using the `--model` flag (in the `readargs.R` file explained in the Quickstart tutorial)."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "``` R\n",
    "library(nlme)\n",
    "\n",
    "processVoxel <-function(v) {\n",
    "    # specify the response variable, Y\n",
    "    Y <- voxeldat[,v]\n",
    "    # specify mixed model (note you can write this in other packages like lme4\n",
    "    e <- try(mod <- lme(Y ~ High+Low, random=~1|subject, method=c(\"ML\"), na.action=na.omit, corr=corAR1(form=~1|subject), control=lmeControl(returnObject=TRUE,singular.ok=TRUE)))\n",
    "    if(inherits(e, \"try-error\")) {\n",
    "        mod <- NULL\n",
    "    }\n",
    "    if(!is.null(mod)) {\n",
    "        # specify contrast values\n",
    "        contr <- c(0, 1,-1)\n",
    "        out <- anova(mod,L=contr)\n",
    "        t.stat <- (t(contr)%*%mod$coefficients$fixed)/sqrt(t(contr)%*%vcov(mod)%*%contr)\n",
    "        p <- 1-pt(t.stat,df=out$denDF)\n",
    "        retvals <- list(summary(mod)$tTable[\"High\", \"t-value\"],\n",
    "                        summary(mod)$tTable[\"Low\", \"t-value\"], t.stat, p)\n",
    "    } else {\n",
    "    # If we are returning 4 dimensional data, we need to be specify how long\n",
    "    # the array will be in case of errors\n",
    "        retvals <- list(999,999,999,999)\n",
    "    }\n",
    "    names(retvals) <- c(\"tstat-High\", \"tstat-Low\", \"tstat-High.gt.Low\", \"p-High.gt.Low\")\n",
    "    retvals\n",
    "}\n",
    "```"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "The `processVoxel` function is run for each voxel number `v`. Thus, `Y` is the BOLD signal at each voxel. This code specifies a mixed effects model with two explanatory variables, `High` and `Low`. The design matrix is made available to the `processVoxel` function environment. There is a random effect of intercept per subject. We handle autocorrelation in the model using an autoregressive model of order 1 (AR1). Note that adding AR1 increases computation time. \n",
    "\n",
    "If the model runs without error, then we compute the p-value of the contrast (where `High` > `Low`). Variables that we wish to save are collected in a vector, and named. The output variables are assembled into files with the prefix specified by the `--output` flag and the variable names.\n",
    "\n",
    "For more information on mixed effects modeling of fMRI data in R, see the document [“fMRI in R”](https://github.com/madhyastha/fmriInR/blob/master/fmriInRWalkthrough.Rmd). The `processVoxel` function can run any model that can be run on a single voxel. This includes structural equation models, growth models, and so on. This function can also compare several models and output the best according to some criteria."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "### Building models\n",
    "\n",
    "When developing your own processVoxel function, it is helpful to run interactively on a few specific voxels. Similarly, if there are errors at a voxel it may be helpful to interactively interrogate the model output. The `--debugfile` flag specifies that the design matrix and voxel data should be written to an R file that can be used for model development and debugging.\n",
    "\n",
    "If you have run `npoint` as directed above, you will have a file called `debug.Rdata` in the `sgedata directory`.\n",
    "\n",
    "You can start R from within the `sgedata` directory, load this file, and see what is defined.\n",
    "``` R \n",
    "        load(“debug.Rdata”)\n",
    "        ls()\n",
    "        [1] \"designmat\"          \"imagecoordtovertex\" \"mask.arrayindices\" \n",
    "        [4] \"voxeldat\"\n",
    "```        \n",
    "The `designmat` data structure contains the design matrix specified by the `setlabels` files.\n",
    "\n",
    "`voxeldat` is a structure that holds all the voxels in the mask. Each column corresponds to 1 voxel in your mask. \n",
    "\n",
    "The `imagecoordtovertex` function uses the `mask.arrayindices` structure to transform image coordinates to vertex numbers. Vertex numbers are values that correspond to a particular set of coordinates. For example, suppose you want to find the data corresponding to voxel x=20,y=42, z=22 in the mni_4mm.nii.gz image. You would call `imagecoordtovertex` as follows.\n",
    "\n",
    "``` R \n",
    "        v <- imagecoordtovertex(20,42,22)\n",
    "        v\n",
    "        [1] 16733\n",
    "```\n",
    "\n",
    "To access the voxel time course (for all subjects and runs) attach the design matrix and create the following Y variable.\n",
    "\n",
    "``` R \n",
    "        attach(designmat)\n",
    "        Y <- voxeldat[,v]\n",
    "        Y\n",
    "```"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.6.3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 2
}
