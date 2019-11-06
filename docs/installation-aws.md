# Installation to use AWS
This section assumes that you have installed neuropointillist already,
and are planning to run it on AWS (in the cloud). The benefit of doing
this is that AWS steeply discounts unused compute capacity (this is
called the "spot" market). You can use this to run jobs that will take
too long or just make your jobs finish more quickly.

In this section, I refer to things that you should do or should install on your
"development computer". This is the computer you are using to write
and test your neuropointillist code, in contrast to any virtual cloud
resources you might use to run your code.

To make sure that everything is working correctly, 
set up neuropoint to run locally or on a cluster
before moving on to AWS. This will allow you to test your docker
container and workflow.

## Get an AWS account if you do not have one
You will need to [create an AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)
if you do not have one. If you are part of a participating educational
institution and have not joined
[AWS Educate](https://aws.amazon.com/education/awseducate/), you might
consider doing that to get some credits to try things out.

## Install Docker if not installed
To use AWS in the way that neuropoint does, you need to package up
your R environment in a Docker container. You will need to [install
Docker](https://docs.docker.com/install/) on your development computer. 

## Install the AWS CLI and AWS  SDK for Python
You will need to install some tools that allow you to
control AWS resources from your development computer using the shell
(AWS CLI)
and using Python (AWS SDK for Python).

First, install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
on your platform. You will also need to [configure it](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

Then install the [AWS SDK for Python](https://aws.amazon.com/sdk-for-python/)
## Install Nextflow
Nextflow is an amazing workflow language that I just discovered while
trying to get neuropoint working with AWS Batch. I move from GNU make
reluctantly and this is good enough, elegant enough, and powerful enough for me to fall
in love. Trust me. [Install Nextflow](https://www.nextflow.io/). Make
sure your Java release is not too new to run nextflow.

## Configure AWS Batch to Run Neuropointillist
There are four steps to using AWS Batch to run neuropointillist
jobs. Scripts to execute these steps are in the directory `aws`.

Change directory to `aws`:
```
cd aws
```

### Step 1. Create a Docker container
- The first step is to create a Docker container that has the R
  packages and other software that you need. The commands to do this
  are in the `dockerbuild` directory. In particular, look at the file
  `docker_install.Rscript` and see if there are R packages you *need*
  that are not installed. In general, you don't want to make the
  container enormous.

It is also possible that you might need to call some Linux commands
that are not installed by default. The base image is based on Amazon
Linux, which uses the `yum` package manager. You can edit the
`Dockerfile` file to install other Linux packages that you  need to
run your application.

To build your container, from within the `aws` directory, type

```
00_dockerbuild
```
This will create a container called `neuropointillist-nextflow`.

You should test this container before trying to run it on AWS to make
sure that there are no unexpected problems. To do this, assuming that
you have run neuropointillist already and generated a directory with a
`Makefile`, try the following.

Modify the line that begins with `npointrun` to begin with the
following prefix.

```
docker run -v $(pwd):/containerdat -w /containerdat -it
neuropointillist-nextflow
```

This will run `npointrun` in the container that you have just
created. If there are problems finding R packages or programs, modify
the`Dockerfile` or the `docker_install.Rscript` file as described
above, rerun `00_dockerbuild`, and try again.

If you have difficulty finding files, make sure that they are all
located in the directory with your Makefile. It will become important
that all the files you need are eventually copied to AWS storage. 

### Step 2. Create an AWS ECR Registry (Optional)
You do not need to do this step if you prefer to use a different
registry that can be accessed by AWS Batch (for example,  Docker
Hub or Quay). You just need to know the path to your container.

There is a charge for storing an image in AWS ECR
[depending on its size](https://aws.amazon.com/ecr/pricing/). You can
determine the size of your Docker image with the command `docker
images`.  As an example, my image cost approximately 18 cents per
month. However, note that if you upload multiple versions of the image
after making corrections, you should delete those, or you can set
rules to automatically delete them in the AWS console.

However, if you wish to use AWS ECR, run the following command:
```
01_createECRRegistry
```
This will print out the path to your image, and link to the AWS
console where you can see it and do any housekeeping to delete old
images.

*Note the path to your image for future configuration.*

### Step 3. Create an AWS Batch Queue
You need to create and configure a structure called an AWS Batch Queue
that uses spot pricing to execute jobs as cheaply as possible. The
drawback of that is that jobs might be killed. This is why Nextflow is
so critical to the process; it can restart jobs that need to be rerun.

Data will be staged in an Amazon S3 bucket. Before you can create the
AWS Batch Queue, create a bucket either using
[the console](https://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html)
or the
[CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3.html).
Note that this name needs to be globally unique, so common names like
`mybucket` 
will be taken.

To create the AWS Batch Queue, provide the bucketname as follows.
```
02_createNpointBatchQueue mybucket
```

## Cleaning Up When Done
After you have finished running your npoint jobs, you will want to
delete any resources that you have used on AWS. 

## Cleanup Step 1. Delete the AWS Batch Queue
You can remove the AWS Batch queue with the command
```
deleteNpointBatchQueue
```

This will remove any jobs and resources you have provisioned, but it
will not remove your S3 bucket storage. Note that there is no charge
for the AWS Batch queue unless you are running things. 

## Cleanup Step 2. Delete the ECR Registry
You can remove your ECR registry with the comand
```
deleteECRRegistry
```
Note that there is a small charge to store containers in ECR, so you
will want to delete the registry and save your container for archival
when you are done.

## Cleanup Step 3: Remove your S3 Bucket (if desired)
You can copy data from your S3 bucket (`mybucket`) to local disk as
follows:
```
aws s3 sync s3://mybucket mybucket-localcopy
```

You can delete the bucket permanently:
```
aws s3 rm s3://mybucket
```


