# npoint
## Usage
`npoint --set1 listoffiles1.txt --setlabels1 file1.csv --set2 listoffiles2.txt  --setlabels2 file2.csv`
`--covariates covariatefile.csv  --mask mask.nii.gz --model code.R  [ -p N | --sgeN N | --slurmN | --pbsN ] --pbsPre PBSpreamblefile --permute N --output output`
`--debugfile outputfile `

If a file called `readargs.R` exists that sets a vector called `cmdargs`, this file will be read to obtain the arguments for `npoint` instead of taking them from the command line. This is intended to make it a little easier to remember the long lists of arguments. 

File inputs that are supported are nifti files. _Cifti, and mgz files will be supported in the future.  Alternatively, the user should also be able to supply a CSV file with the data in it, for other types of neuroimaging analysis that might not conform to this model._ The file type is determined simply by the extension (.nii = cifti, .nii.gz = nifti, .mgz is vertex surface). 

`--set1`, `--set2`, ..`--set5`
 By default, the command line variant of the program supports up to 5 input sets. These sets can correspond to longitudinal data points. If more than five input file sets are necessary one should use the programmatic interface, or organize your data as a single input file set in long format with corresponding covariates. Each setfile (`listoffiles1.text ... listoffiles2.txt`) is a text file that contains the filenames in each set, one per row. These sets can correspond to longitudinal data points. They do not have to have the same subjects in each set (i.e., there can be missing data if the models you intend to use support that). **At least one set and corresponding setlabel must be provided**
 
`--setlabels1`, `--setlabels2`, ... `setlabels5`
 
The setlabel files are csv files that specify variables that correspond to the files in the sets provided above. There must be exactly the same number of setlabel files as sets. If the MRI data files in each set are three dimensional, the list of files in the set  should have exactly the same number of entries as the corresponding label csv file.  If the files are four dimensional (fMRI data), the corresponding label csv files should include one entry per volume (TR). The data from the setlabels must be provided in the same order as the data in the set files. Normally, set label files will include (at the least) an id number and a time point for each 3D file that is specified. For 4D files, set label files will probably include an id number, time point, TR and elements of the fMRI design matrix. The headers of the setlabel files must be consistent across sets, and consistent with headers in the covariate file, if specified, below. **At least one set and setlabel must be provided.**

`--covariates`  Subject identifiers can be associated with any number of covariates as specified in the covariate file, which are csv files. These files can contain additional information about subjects, for example, age at a particular time or IQ. All information in covariate files can also be specified in the setlablels; this option is largely a convenience option. If a covariate file is specified, it will be merged with the content of the setlabel files based on all the header fields that are common to both. An error will occur if there are no header fields in common. 

|Subjectid, |time, |age, |IQ |
|----------|-----|----|---|
|1,         | 1,   |13,  |110|
|2,         |1,    |13.2,|115|
|3,         |1,    |12.9,|98 |


`--mask` The mask must be a file of the same type and size of the first three dimensions  of all the set inputs. The mask must contain 1s and zeros only and computation will be limited to those voxels/vertices which are set to 1 in the mask. (**required**)

`--model` The model specifies the R template code to run the model and return results.  This can also include any initialization code (e.g., libraries that must be included. The model must define the function `processVoxel(v)` that takes as an argument a voxel number `v`. (**required**).

`-p x` The `-p` argument specifies that multicore parallelism will be implemented using `x` processors. An warning is given if the number of processors specified exceeds number of cores. **See notes below on running a model using multicore parallelism.**

`--sgeN N` The `--sgeN` argument specifies to read the data and divide it into `N` jobs that can be submitted to  the SGE (using a script that is generated called, suggestively, `runme.sge`) or divided among machines by hand and run using GNU make. If SGE parallelism is used, we assume that the directory that the program is called from is read/writeable from all cluster nodes. **See notes below on running a model using SGE parallelism.**

`--slurmN N` The `--slurmN` argument specifies to read the data and divide it into `N` jobs that can be submitted to a Slurm scheduler (using a script that is generated called, suggestively, `runme.slurm`) or divided among machines by hand and run using GNU make. If Slurm is used, the template file **slurmjob.bash** must be edited!!! Unlike SGE, Slurm works best if you give good estimates of the time your program will take to run, the amount of memory it needs, and if you select the number of jobs to make each one not very small. The file that is written is currently a template based on Harvard's cluster configuration. Like with SGE, we assume that the directory that the program is called from is read/writeable from all cluster nodes. At the risk of oversharing, Slurm's name derives from Simple Linux Utility for Resource Management, but I find it rather funny to sound it out in my head as I have been adding this feature. **See notes below on running a model using the Slurm Workload Manager.**


`--pbsN N` Much like the flag `--slurmN` described above, the `--pbsN` argument specifies to read the data and divide
it into `N` jobs that can be submitted to a Torque PBS  scheduler
(using a script that is generated called `runme.pbs`) or divided among
machines by hand and run using GNU make. If PBS is used, the
template file **pbsjob.bash** must be edited!!! PBS
works best if you give good estimates of the time your program will
take to run, the amount of memory it needs, and if you select the
number of jobs to make each one not very small. The file that is
written is a template based on the Universty of Michigan's Flux cluster
configuration. Like with SGE, we assume that the directory that the
program is called from is read/writeable from all cluster nodes.
 **See notes below on running a model using Torque PBS.**

`--pbsPre PBSpreamblefile` By default the `--pbsN` flag will generate a Torque PBS batch file that you will need to edit. You can override this by specifying a preamble file with all the settings that will be used instead of these default values. You can only use this flag with the `--pbsN` option.  **See notes below on running a model using Torque PBS.**

`--permute N` Now for something completely different. If you would like to run the same model repeatedly to create a null distribution for cluster correction, this flag is for you. If you specify this flag and a number of permutations `N`, your `processVoxel` function will be executed over the entire mask `N` times (rather than splitting up the data into `N` pieces and running the function on each piece). If you do this, you can take advantage of ETAC state of the art cluster correction from AFNI. This option is why support for AWS Batch was added. This is computationally intensive, but you can use discounted compute resources on AWS and do permutation testing fairly inexpensively.

If you choose this option, you will probably want to run on a cluster or on AWS Batch. 

`--output` Specify an output prefix that is prepended to output files. This is useful for organizing output for SGE runs; you can specify something like `--output model-stressXtime/mod1` to organize all the output files and execution scripts into a subdirectory. In addition, the model that you used and the calling arguments will be copied with this prefix so that you can remember what you ran. This is modeled off of how FSL FEAT copies the .fsf file into the FEAT directory (so simple and so handy)! (**required**)

`--debug debugfile` Write out external representations of the design matrix, the fMRI data, and a function called `imagecoordtovertex`, which maps three-dimensional image coordinates (e.g. from fslview) into a vertex number, to the file `debugfile`. This may be useful for development and testing of your model, or troubleshooting problems with the setfiles or covariate files. The debugfile will be prefixed by the output prefix. See the Vignette for instructions for how to use the debugfile.

## Writing the processVoxel function
This function takes a single value `v` which is a numeric index for a voxel. The code should also load any libraries that you need to support your model (e.g., `nlme`). Before calling `processVoxel`, the code will have attached to the design matrix, so that you have access to all of the named columns in this matrix. Note that we attach to minimize memory copies that might be necessary when running in multicore mode.

After you run your model, you should create and return a `list` structure in `R` that contains the values that you want to write out as files. Single scalar values will be combined and reassembled as three-dimensional files, and lists of values (e.g., random effects) will be reassembled as four-dimensional files.

## IMPORTANT: General considerations for running in parallel 
You will be doing the same thing over a lot of voxels in some kind of loop. If your model generates an error, you will lose the entire job. Therefore, you want to be proactive about trapping errors of all types. Specifically, multicore parallelism is a little touchier with respect to error handling than running in a loop, so it is entirely possible that a code that runs correctly for SGE parallelism does not run on a multicore.

Depending on what package you are using in your model and how it is compiled, you may find that the package or underlying libraries themselves are multi-threaded. This will be obvious if you run `top` while executing your model on a multi-core machine. If things are working well, the `R` processes should show up as using up to 100% of the CPU. If your parallelism is fighting with multithreading, you will see your processes using _over_ 100% of the CPU. This is not a good thing! It means that two levels of parallelism are fighting with each other for resources. When they do this, you might find that jobs take many times longer than they should, or worse, never complete.

You will need to figure out how to turn off any underlying
parallelism. For the `nlme` library you should set the environment
variable `OMP_NUM_THREADS=1` in your shell. Setting this variable in
the R script did not work (although it might be that if I do so before
loading the `nlme` library it would work). However, other libraries
may have other environment variables that should be manipulated.

Practically, I recommend running using SGE parallelism (or whatever
scheduler that you have) to give yourself the widest range of
opportunities to complete your job using limited resources. If you do
that, you can use `make` on a multicore machine or you can use a batch
scheduler.  You can even copy files to multiple computers and run
subsets of the job on different machines. Desparate times. I've been
there more often than seems fair.

## Running a model using SGE parallelism 

The `readargs.R` file in `example.rawfmri` is configured so that it will create a directory called `sgetest` with the assembled design matrix file (in rds format), the split up fMRI data (also in rds format), and files to run the job. These files are:

`Makefile` This file contains the rules for running each subjob and assembling the results. Note that the executables `npointrun` and `npointmerge` must be in your path environment. You can run your job by typing `make -j <ncores>` at the command line in the `sgetest` directory, or by calling the script `runme.local`, which will use 4 cores by default. You can also type `make mostlyclean` to remove all the intermediate files once your job has completed and you have reassembled your output (by any method). If instead you type `make clean`, you can remove all the rds files also. 

For convenience when using cluster systems where you need to give estimates for run time and memory use, the Makefile defines a `TIME` variable to be a command which will dump out information about these things. Unfortunately, the appropriate command is somewhat different across UNIX variants. If it is not a Linux or Mac variant of UNIX, this may be unset. 

`sgejob.bash` This is the job submission script for processing the data using SGE. Note that `npointrun` needs to be in your path. The commands in the job submission script are bash commands.

`runme.sge` This script will submit the job to the SGE and call Make to merge the resulting files when the job has completed. It is an SGE/Make hybrid.

## Running a model using the Slurm Workload Manager


`Makefile` This file contains the rules for running each subjob and
assembling the results. See description of the `Makefile` in **Running a model using SGE parallelism**, above.

`slurmjob.bash` This is the job submission script for submitting the
job to the Slurm Workload Manager. **Note that you must edit this file
before submitting the job.** The defaults that are written here
probably won't work for you; they are modeled after Harvard's NCF
cluster and should be thought of as placeholders. The first thing to
change is the partition, which is set to `ncf_holy` by default. You
will need to change this to a partition that you have access to on
your Slurm system. Next, you need to give a good estimate for the
amount of memory, in MB, your job will use (`--mem`). You can get a
reasonable estimate by running `make` on your local machine to run one
job sequentially. The `time` command will give you statistics on how
much memory each job uses. You would probably want to look at the
Maximum resident set size, which is given in KB (divide by about 1000
to obtain MB). Assuming your jobs are approximately the same size, you
should be able to double or triple this and use that figure as an
estimate. You also need to provide an estimate for the time you expect
each job to take; it will be terminated if the job does not complete
within that time. You can look at the elapsed wall clock time to get
this estimate. The cluster might be slower on a single job than your
desktop, so make sure to multiply this wall clock time to provide an
estimate for the cluster.

`runme.slurm` This script will submit the job to the Slurm Workload
manager. The job is an array job that includes as many tasks as you
specified. You will get an email when your job has completed. At that
point, you can then come back to this directory and type `make` to
merge the output files.


## Running a model using Torque PBS

`Makefile` This file contains the rules for running each subjob and
assembling the results. See description of the `Makefile` in **Running a model using SGE parallelism**, above.

`pbsjob.bash` This is the job submission script for submitting the job
to PBS. **Note that you must edit this file before submitting the
job.** The defaults that are written here probably won't work for you;
they are modeled after the University of Michigan's Flux cluster and
should be thought of as placeholders. All of these defaults can be overridden using the `--pbsPre` flag, which allows you to specify a preamble file with defaults that will be used instead of the program defaults.

The first thing to change is the partition, which is set to `support_flux` by default. You will need to change this to a partition that you have access to on your system. Because the job is submitted as a task array job, you can leave the number of nodes and processors alone.
However, you will need to estimate how much memory, in MB, your job will use (`pmem=`). You can get a reasonable
estimate by running `make` on your local machine to run one job
sequentially. The `time` command will give you statistics on how much
memory each job uses. You would probably want to look at the Maximum
resident set size, which is given in KB (divide by about 1000 to
obtain MB). Assuming your jobs are approximately the same size, you
should be able to double or triple this and use that figure as an
estimate. You also need to provide an estimate for the time you expect
each job to take; it will be terminated if the job does not complete
within that time. You can look at the elapsed wall clock time to get
this estimate. The cluster might be slower on a single job than your
desktop, so make sure to multiply this wall clock time to provide an
estimate for the cluster. Alternatively, you can run a job and look at the report that you get emailed back. If you start with a relatively high estimate for memory and wall clock time, you can scale it back.

`runme.pbs` This script will submit the job to PBS.
The job is an array job that includes as many tasks as you
specified. You will get an email when your job has completed. At that
point, you can then come back to this directory and type `make` to
merge the output files.

## Permutation testing using AWS Batch
If you have specified permutation testing, you will get a file in the directory created by `npoint` called `make.nf`, which is a nextflow workflow. It is assumed you have installed [nextflow](https://www.nextflow.io/) and installed and configured the [AWS CLI] (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html). See [AWS installation instructions](installation-aws.md).

There will be a skeleton file called `nextflow.config`. To use AWS Batch, you will need to edit this file to specify the identifier of the container that you are using. If you use the scripts provided 
You will need to create an S3 bucket on AWS, which will be used to stage data and partial results. Assume this bucket is called `mybucket`.


To run, specify the bucket as follows.

```
nextflow run make.nf -bucket-dir s3://mybucket
```

You can monitor the jobs by going to the AWS Batch console and looking at the Dashboard. When they have completed, by default, the `make.nf` file specifies that the results should be copied into the current directory. You can change this by modifying the `publishDir` directive in the `make.nf` file.

By default, the job queue is created to allow a maximum of 256 virtual cpus. You can edit this in the AWS Batch console. 

## Running a model using multicore parallelism

The `readargs.R` file in the `example.flournoy` directory is configured so that it will use 24 cores to compare two models. You should change this number to be lower if your  machine does not have 24 cores. Note that data are not included for `example.flournoy`.

Note that the syntax for trapping errors is a little bit different. We check to see whether the error inherits from `try-error`.

# npointrun
Run a model on a single data set sequentially, without data splitting

## Usage
`npointrun --mask mask.nii.gz --model code.R  --designmat designmat.rds`

`--mask mask.nii.gz` Nonzero mask voxels must indicate locations of the data in the corresponding RDS file.  The name of the mask is used to obtain the name of the RDS data file (substituting .nii.gz for .rds). (**required**)

`--model code.R` The model specifies the R template code to run the model and return results. The model must define the function `processVoxel(v)` that takes as an argument a voxel number `v`. (**required**)

`--designmat designmat.rds` The design matrix must be the same dimensions as the voxeldat, read from the RDS file. (**required**)


# npointmerge
Merge some number of files by summing them

## Usage
`npointmerge output <list of files>`


