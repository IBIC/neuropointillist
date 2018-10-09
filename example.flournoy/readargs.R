cmdargs <- c("-m","mask.nii.gz", "--set1", "setfilenames1.txt",
             "--set2", "setfilenames2.txt",
             "--set3", "setfilenames3.txt",             
             "--setlabels1", "setlabelsn1.csv",
             "--setlabels2", "setlabelsn2.csv",
             "--setlabels3", "setlabelsn3.csv",             
             "--covariates", "Flournoy.new.csv",
             "--model", "longModelLog.R",
             "--testvoxel", "10000",
             "--output", "logonly/fl.",
             "--debugfile", "debugfileoutput",
             "--sgeN", "50")
             
