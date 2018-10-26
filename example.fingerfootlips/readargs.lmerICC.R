cmdargs <- c("-m","mask.nii.gz", "--set1", "setfilenames1.txt",
             "--set2", "setfilenames2.txt",             
             "--setlabels1", "setlabels1.csv",
             "--setlabels2", "setlabels2.csv",             
             "--model", "lmerICC.R",
             "--output", "lmerICC/icc.",
             "--debug", "debug.Rdata",
             "--sgeN", "50")
             
