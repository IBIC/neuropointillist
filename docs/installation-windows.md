# Installation for Windows 10
It is rather tricky to get `neuropointillist` to work natively on Windows because it relies so much upon Linux conventions. The easiest way to run it is to install the Windows Subsystem for Linux, as below. 

## Install Linux
The first prerequisite is the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10). If you do not already have this installed, follow the directions in this link, and make sure to select Debian as your flavor of Linux to avoid heartache later. (If you have already installed a different flavor of Linux that is actually fine.)


## Pretend you are on a Linux workstation and follow the Linux installation instructions
Follow the [Linux installation instructions](installation-linux.md) from here. 

An important thing you will want to know is that your files on your Windows machine are accessible from the Linux terminal window in `/mnt/c` (assuming your files are in the `C:` file system. So in Linux, you can change into your Windows home directory (and find all the files you have created) with the following command (replace `tara` with your own user name):

```bash
cd /mnt/c/Users/tara/
```



