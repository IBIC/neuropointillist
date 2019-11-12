## Cluster Correction for Multiple Comparisons

`neuropointillist` does not correct for multiple comparisons, but this
is something that you need to do afterwards.

There are currently two approaches to cluster correction.

## [Simulated Noise](simulated_cluster.md)
The first uses the spatial structure of noise in fMRI data and FSL and AFNI tools to do cluster correction. Many thanks to Kelly
Sambrook  for helping me to write this section of the manual. 

## [Permutation Testing/ETAC](permutation_testing.md)
The second approach runs `npoint` in permutation testing mode to generate permutations, and then uses AFNI tools to run the state of the art ETAC: Equitable Thresholding and Clustering. ETAC is a method that applies multiple per-voxel thresholds to control the overall False Positive Rate. To make it easier for you to do this, `npoint` has support for using AWS cloud computing.  Many thanks to John Flournoy for writing this section of the manual.

