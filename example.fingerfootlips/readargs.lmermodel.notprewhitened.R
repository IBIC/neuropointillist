cmdargs <- c("-m","mask.nii.gz", "--set1", "setfilenames1.txt",
             "--set2", "setfilenames2.txt",             
             "--setlabels1", "setlabels1.csv",
             "--setlabels2", "setlabels2.csv",             
             "--model", "lmermodel.R",
             "--output", "lmer.notprewhitened/m.",
             "--debug", "debug.Rdata",
             "--sgeN", "50")
             
