cmdargs <- c("-m","mask.nii.gz", "--set1", "setfilenames1.txt",
             "--set2", "setfilenames2.txt",
             "--set3", "setfilenames3.txt",
             "--setlabels1", "setlabels1.csv",
             "--setlabels2", "setlabels2.csv",
             "--setlabels3", "setlabels3.csv",
             "--covariates", "Flournoy.new.csv",
             "--model", "model2.R",
             "--output", "comparemodels/fl.",
             "--debugfile", "debugfileoutput",
             "--sgeN", "24")
             
