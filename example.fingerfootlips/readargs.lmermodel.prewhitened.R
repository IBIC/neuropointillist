cmdargs <- c("-m","mask.nii.gz", "--set1", "setfilenamesPrewhitened1.txt",
             "--set2", "setfilenamesPrewhitened2.txt",             
             "--setlabels1", "setlabels1.csv",
             "--setlabels2", "setlabels2.csv",             
             "--model", "lmermodel.R",
             "--output", "lmer.prewhitened/m.",
             "--debug", "debug.Rdata",
             "--sgeN", "56")
             
