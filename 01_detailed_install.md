## Installing Neuropointillist on your local machine (for macs)
Make sure you have the necessary programs and packages installed.

Instructions adapted from: http://ibic.github.io/neuropointillist/installation.html

#### Needed programs:
* R
* Python 2.7 or later

Note that you only need to install the Python and R packages once on your local machine; after they have been installed, neuropointillist will be able to load them as needed:

#### Needed Python packages
* argparse (for R's argparse package)
* json (for R's argparse package)
* nibabel

The simplest way to install python packages is through pip ([instructions for download here](https://pip.pypa.io/en/stable/); note that pip installs automatically with [Anaconda/miniconda](https://conda.io/docs/user-guide/install/index.html)):

```
pip install argparse
pip install json
pip install nibabel
```

#### Needed R packages
* argparse
* doParallel
* Rniftilib
* nlme (if you're using the tutorial's model)
* neuropointillist

The simplest way to install the first 4 R packages is to open R and run the following commands:

```
install.packages("argparse")
install.packages("doParallel")
#Rniftilib must be installed from the source
install.packages("http://ascopa.server4you.net/ubuntu/ubuntu/pool/universe/r/r-cran-rniftilib/r-cran-rniftilib_0.0-35.r79.orig.tar.xz", repos=NULL)
install.packages("nlme")
```

To install the neuropointillist package, you must first clone the neuropointillist repository to your local machine. To do this in Terminal, navigate to the folder you want to put the repository in and run the following:

`git clone https://github.com/IBIC/neuropointillist.git`

Then in Terminal, cd into the neuropointillist folder you just cloned. There should be yet another neuropointillist folder in this folder. Make sure you're in the first neuropointillist folder but not the second. In other words, if the folder structure looks like ~/Desktop/neuropointillist/neuropointillist, you should be in ~/Desktop/neuropointillist

Open R and run the following to install the neuropointillist package:

`install.packages("neuropointillist", repos=NULL, type="source")`

**Now your computer should be set up to run neuropointillist!**
