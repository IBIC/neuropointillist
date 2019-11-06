
# Installation

This is a brief overview of installation instructions for people who
are fairly comfortable installing things on their systems. More
detailed instructions for [MacOS](installation-mac.md),
[Linux](installation-linux.md), and
[Windows 10](installation-windows.md) are also available. Further,
part of the beauty of brute force computing is that you can pay for cloud
computing to run your code if you do not have a cluster. If you want
to do this you should see the [optional installation instructions for AWS](installation-aws.md).

You will need the R packages `Rniftilib`, `argparse`,  `doParallel` and `reticulate` to be installed. 

`argparse` requires Python version >= 2.7 and Python packages `argparse`.

**Instructions for installing `Rniftilib` may be found [here.](http://r-forge.r-project.org/R/?group_id=427)**

Note that as of 9/2017, `Rniftilib` is not installing per these instructions. You can install from source (from any mirror) as follows.

``` R
install.packages("http://ascopa.server4you.net/ubuntu/ubuntu/pool/universe/r/r-cran-rniftilib/r-cran-rniftilib_0.0-35.r79.orig.tar.xz", repos=NULL)
```

Once all prerequisites are installed and you have pulled the `neuropointillist` repository, locally install the package. To do this, `cd` into the repository. You will have a `neuropointillist` subdirectory. Start `R` and type

``` R
install.packages("neuropointillist", repos=NULL, type="source")
```

If you are planning to do development on the R package, it might help to have the R package `devtools`. If you are actually doing development, you should also install the R package `roxygen2`.

`devtools` depends on the Debian package `libcurl4-openssl-dev`, so you might need a system administrator to make sure that is installed. If you have installed `devtools`, you can locally install the package as follows.


``` R
library(devtools)
install("neuropointillist")
```
**! Note that `neuropointillist` requires R version >= 3.2.3**

Make sure that the repository directory which contains the R scripts `npointillist` and `npointrun` is in your path.

