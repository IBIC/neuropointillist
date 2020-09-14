# Installation for Linux

## Install R 
Before you do anything, you need to have the programming language R (version >= 3.2.3). Specific instructions for installing R on the different flavors of Linux are described on [CRAN](https://cran.r-project.org/bin/linux/). For Debian, if you are installing in a Windows Subsystem for Linux, you would do the following:

```bash
sudo apt-get update
sudo apt-get install r-base r-base-dev
```
## Install Python if you do not have it

To test whether you have Python, you can do:

```bash
python --version
```

If this does not return something useful indicating the Python version, you probably do not have Python installed, and you can install it with your package manager. 

For Debian and Ubuntu:

```bash
sudo apt-get install python
```

For Red Hat and other derivatives:

```bash
sudo yum install python
```

If you are just beginning to work with Python and are interested in having a lot of data science libraries ready to go, you might consider installing the [Anaconda Python distribution](https://www.anaconda.com). Both can exist simultaneously on your system, increasing the chances that one will work.

After your travails, Python should be in your path (you might have to start a new terminal window) and you should be able to see what version of Python you are running.

```bash
python --version
```

## Download neuropointillist
There are two ways to install `neuropointillist`. The first is to download the package as a zip (archive) file from the [Github repository](https://github.com/IBIC/neuropointillist). Here, we pull it using `wget`, unzip it, and rename it to be called `neuropointillist`.

```bash
wget https://github.com/IBIC/neuropointillist/archive/master.zip
unzip master.zip
mv neuropointillist-master neuropointillist
```

The second way is to clone it using Git. You can install Git for your Linux flavor if it is not installed.

```bash
git clone https://github.com/IBIC/neuropointillist.git
```


## Install dependencies and neuropointillist

Change into the directory where you have downloaded `neuropointillist`. There will be a subdirectory called `neuropointillist` within that directory; this contains the R package. 

Start R at the `bash` command line.

```bash
R
```
Within R, install the dependencies `argparse`, `RNifti`, `doParallel` and `reticulate`. 

```R
install.packages("argparse")
install.packages("RNifti")
install.packages("doParallel")
install.packages("reticulate")
```

Depending on what version of R you are running, you might also need to install `nlme`.

```R
install.packages("nlme")
```

Once all prerequisites are installed, you can install neuropointillist. Once again, make sure you are in the directory where you downloaded `neuropointillist`, or change into that directory from within R. 

``` R
install.packages("neuropointillist", repos=NULL, type="source")
```

## Modify Your Path

Finally, put the repository directory that contains the scripts `npoint`, `npointrun` and `npointmerge` into your PATH variable. You can do this on the command line every time you start a new terminal as follows. Make sure you put the path where YOU downloaded the github repository for neuropointillist.

```
export PATH=$PATH:~/neuropointillist
```

Alternatively, you can put this line into your `.bashrc` file.


