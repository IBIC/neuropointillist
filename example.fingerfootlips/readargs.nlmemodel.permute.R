
cmdargs <- c("-m","mask.nii.gz", "--set1", "setfilenames1.txt",
             "--set2", "setfilenames2.txt",             
             "--setlabels1", "setlabels1.csv",
             "--setlabels2", "setlabels2.csv", 
             "--model", "nlmemodel.permute.R",
             "--testvoxel", "10000",
             "--output", "nlmemodel.perms/n.p.",
             "--debugfile", "debug.Rdata",
             "--slurmN", "1",
             "--permute", "1000")

