## Cluster Correction for Multiple Comparisons

`neuropointillist` does not correct for multiple comparisons, but this
is something that you need to do afterwards. Many thanks to Kelly
Sambrook for helping me to write this section of the manual. This
section is currently a work in progress.

You will need to know the spatial structure of the noise in your fMRI
data. It is *very important* to use the residual noise images for this
step, and not your actual fMRI data, because you do not want to pick
up the spatial structure of the brain. Likewise, you should estimate
the spatial structure of the noise from the residual noise images
instead of using the smoothing kernel that you apply to the fMRI data.

We rely upon tools from AFNI for doing this. The AFNI command `3dFWHMx`  can be used for this purpose. 

### If you have done your first level analysis using FSL
Use the `res4d.nii.gz` from the subject's FEAT directory. You will also need to use the `mask.nii.gz` from each subject's FEAT directory, because `3dFWHMx` will not work properly with the residual images. We also use the `-detrend` flag to detrend the data because [Rick Reynolds says so](https://afni.nimh.nih.gov/afni/community/board/read.php?1,150464,150469#msg-150469).

`3dFWHMx -detrend -mask mask.nii.gz -acf NULL -input res4d.nii.gz`

This command outputs four values (three ACF parameters - a, b and c -  and an estimate
of the FWHM) for each input pair (res4d.nii.gz and mask). You should
average the ACF parameters across all inputs, to obtain an average for a, b, and c. It is also a good idea to check these parameters; the first parameter must be between 0 and 1, and the second and third parameters must be positive.

The next step is to use `3dClustSim` to make the cluster threshold
tables. This command needs a brain mask in standard space (`MNI_mask.nii.gz`), the average ACF parameters average_a, average_b, and average_c computed above. 
The `-LOTS` option sets a list of default p-values and alpha-values to use for the cluster thresholding tables and `-nodec` option, which prints cluster size threshold in whole numbers, instead of the default, which is to one decimal place, are helpful with formatting the output of the cluster thresholding tables.

`3dClustSim -LOTS -nodec -mask MNI_mask.nii.gz -acf average_a average_b average_c -prefix CLUSTER-TABLE`


After creating the cluster threshold tables, you will need to identify
the correct size cluster for your choice of p, alpha, sidedness, and
the type of NN clustering approach (see the AFNI documentation, and
note that NN=3 corresponds to what is used by FSL).

### If you have done your first level analysis using other software
Instructions are probably similar to above. If you can provide more detailed info on what to use as a mask or residual file, please let us know.

### If you are doing your analysis in R 
You can in fact actually write out 4D residual images, although 4D output has not been tested really well. You could apply a similar procedure to that described above.
