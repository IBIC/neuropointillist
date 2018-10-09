# Installation on MacOS
Installation on MacOS is very similar to installation on Linux. 

## Install R 
You can download R if you do not have it from [CRAN](https://cran.r-project.org/bin/macosx). You will need a version of R that is >= 3.2.3.

## Install Python if you do not have it

Macs generally come with Python installed, so you should be fine. You can test to see that you have a Python version >= 2.7 with the following command:

``` python --version```

If this does not return anything useful, or you are just beginning to
work with Python and are interested in having a lot of data science
libraries ready to go, you might consider installing the
[Anaconda Python distribution](https://www.anaconda.com). Both can
exist simultaneously on your system, increasing the chances that one
will work.

After your travails, Python should be in your path (you might have to
start a new terminal window) and you should be able to see what
version of Python you are running.

```python --version```

## Download neuropointillist
There are two ways to install `neuropointillist`. The first is to download the package as a zip (archive) file from the [Github repository](https://github.com/IBIC/neuropointillist). Here, we pull it using `wget`, unzip it, and rename it to be called `neuropointillist`.

```wget https://github.com/IBIC/neuropointillist/archive/master.zip
unzip master.zip
mv neuropointillist-master neuropointillist
``

The second way is to clone it using Git. You can install Git for your Linux flavor if it is not installed.

```git clone https://github.com/IBIC/neuropointillist.git```


## Install dependencies and neuropointillist

Change into the directory where you have downloaded `neuropointillist`. There will be a subdirectory called `neuropointillist` within that directory; this contains the R package. 

Start R and install the dependencies `argparse`, `Rniftilib`, `doParallel` and `reticulate`. 

> install.packages("argparse")
install.packages("http://ascopa.server4you.net/ubuntu/ubuntu/pool/universe/r/r-cran-rniftilib/r-cran-rniftilib_0.0-35.r79.orig.tar.xz", repos=NULL)
> install.packages("doParallel")
> install.packages("reticulate")

Depending on what version of R you are running, you might also need to install `nlme`.
> install.packages("nlme")


Once all prerequisites are installed, you can install neuropointillist. Once again, make sure you are in the directory where you downloaded `neuropointillist`, or change into that directory from within R. 

``` R
install.packages("neuropointillist", repos=NULL, type="source")
```



