# Neuropointillist Tutorial

This is a simple tutorial for using neuropointillist to run some examples. This assumes that you have already followed the directions in the Installation section of the README.

## Setting your PATH variable
After you have downloaded and installed the neuropointillist programs, you need to add that directory to your PATH variable. Suppose that you have downloaded the neuropointillist package into `~/neuropointillist`. Assuming you are running the bash shell, edit your PATH as follows:

`export PATH=$PATH:~/neuropointillist`

This code will make it so that when you type `npoint` or `npointrun` at the command line, your shell can find them. You can put this in your `~/.bashrc` file (if you use bash) so that you don’t have to do this every time you log in.


## fmri Example
### Quick start.
Go into the directory `example.rawfmri`. This example has simulated fMRI data for 8 subjects, two sessions each. 

`cd example.rawfmri`

Look at the arguments in the file `readargs.R`. You don’t need to change any of these, but these are used by `npoint` to specify the command line options.

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

`neuropoint`

This will create the subdirectory `sgedata`, as specified by the `--output` flag. In this subdirectory are two scripts of interest. The script `runme.local` uses the UNIX utility `make` to run the model on the machine you are logged in to. The script `runme.sge` submits the job to the default SGE cluster  using `qsub`. Note that if SGE is not correctly configured, this script will not work.

To run the model on each voxel in the mask, type either:

`runme.local`

or, if you have an SGE cluster

`runme.sge`

When everything has completed, you will have four files with results:

`sim.p-High.gt.Low.nii.gz
sim.tstat-High.gt.Low.nii.gz
sim.tstat-High.nii.gz
sim.tstat-Low.nii.gz`


# Building models


load(“debug.Rdata”)

ls()

attach(designmat)

v <- imagecoordtovertex(33,36,31)


Quick start.
Go into the directory flournoy.example. 

cd flournoy.example

Ask someone where to find the sfic directory that has the data you need to run this example (it is not on github). Copy that directory into the flournoy.example directory:

cp -r /path/to/sfic sfic

Look at the arguments in the file readargs.R. Most of these you can leave alone, but look at the option to the -p flag. This is 24, which assumes you have 24 processors on your computer. See how many processors you do have:

nproc

You should replace 24 with the number of processors on your machine, provided by the nproc command, especially if it is less!

You need to set an environment variable when using multithreading as above to avoid creating too many threads. If you forget this step, your program might not complete. Do this as follows:

export OMP_NUM_THREADS=1

Now run the example. This example is totally canned for you so that it reads all the command line flags from the readargs.R file. So all you need to type is

npointillist

You should see output that looks like the following:


Now wait for a bit. This will take a little time to complete.

When you get your command prompt back, you should have four files in the directory comparemodels:

fl.dAIC.nii.gz, fl.dBIC.nii.gz, fl.LR.nii.gz and fl.LRp.nii.gz

What it means. 
This is an example of longitudinal fMRI task data from John Flournoy. Adolescents were scanned at 3 waves (mean age 10, 13, and 15) while making evaluations of self and other in the social and academic domains. The “other” target was a fictional character, Harry Potter, about whom participants all had substantial knowledge. An equal number of items were positive and negative. Sample phrases included “I am popular”, “I wish I had more friends”, “I like to read just for fun,” and “Writing is so boring”.  Thus, the goal was to look at activation related to self and other in different domains throughout adolescent development.

Data. 
The data are in a directory called sfic (this is not on github - you need to find it elsewhere). Each file has a name of the following format (question marks are wildcards):

s???_t?_con_????.nii

Let’s break this down:
s??? is the subject id
t? is the timepoint (1-3)
con_??? indicates the contrast (1-4)

The contrasts 1-4 correspond to TargetXDomain (1= SelfXAcademic, 2=SelfXSocial, 3=OtherXAcademic, and 4=OtherXSocial). These are the statistics that are output from a first level analysis. 

If you go into the example.flournoy directory, you can see that setfilenames1.csv contains all the files corresponding to timepoint 1, setfilenames2.csv has all the files corresponding to timepoint 2, and setfilenames3.csv has all the files corresponding to timepoint 3. Similarly, the setlabels1.csv file has a subject id number, target code, domain code, and time code corresponding to the information embedded in each of the file names in setfilenames1.csv.

Covariates. 
The arguments in readargs.R specify that there is a covariates file, Flournoy.new.csv. Covariates are data that are normally per subject/timepoint, or possibly just per subject - they are merged with the collected data across all timepoints, assuming that column headers in the setlabels files are the same things as values in the covariates file. If you look at Flournoy.new.csv you can see that the covariates file includes a subject id number, the time point, age of the subject at that time point, sex, and pubertal development status.

Model.
The readargs.R file specifies that the model we are running in this example is model2.R. The model code is all that you should ever need to write. In it, you define a processVoxel function that takes a voxel number (v), looks it up in a global data structure (voxeldat), and uses column names of the design matrix (formed from the setlabels and the covariates) to do some calculation and return important things. 

If you take a look at this particular model code, you can see that this code tests two linear models (mod1 and mod2). The second model includes a term that tests whether there is an interaction between the target and the domain. The two models are compared and we output (in retvals) a list of model fit statistics. The names of these retvals are used to create output file names. 

Thus, the purpose of this model is to compare two specific models and output voxelwise fit statistics.  




