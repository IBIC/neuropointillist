cmdargs <- c("-m","oneslice_4mm.nii.gz", "--set1", "setfilenames1.txt",
             "--set2", "setfilenames2.txt",             
             "--setlabels1", "setlabels1.csv",
             "--setlabels2", "setlabels2.csv",             
             "--model", "fmrimodel.R",
             "--output", "slurmdata/sim.",
             "--debug", "debug.Rdata",
             "--slurmN", "10")
             
