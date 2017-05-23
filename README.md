# Flexible modeling of neuroimaging data in R, point by point

<img src="docs/logo.jpg" alt="Neuropointillist logo" height="250"/>

# Overview

This project contains an in-development R package (called
`neuropointillist`) which defines functions to help scientists to run voxel-wise models using R on neuroimaging data. Why would one like to do this, rather than using a dedicated fMRI analysis packages?

First, fMRI analysis packages are generally quite limited in the models that they can run. This package can help you run structural equation models on your fMRI data if you wish.

Second, it is really instructive to understand what fMRI software is doing with your data. T statistics are so much sweeter when you have generated them with your own R code.

The `neuropointillist` package has functions to combine multiple
sets of neuroimaging data, run arbitrary R code (a "model") on each
voxel in parallel, output results, and reassemble the data. Included
are three standalone programs. `npoint` and `npointrun` use the
`neuropointillist` package, and `npointmerge` uses FSL commands to
reassemble results.

There are some examples included in this package that use data that we cannot release. These are useful only for looking at modeling code or for inspiration. However, we have simulated two timepoints of fMRI data and have a complete example and a worked vignette.

