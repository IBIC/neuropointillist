import nibabel as nb
from glob import glob
import sys 

#get names of all mask files
mask_files = glob('./indiv_masks/*.nii.gz')
#load all mask files
masks = [nb.load(mask) for mask in mask_files]

#concat across mask files and get logical AND across masks
sum_data = nb.concat_images(masks).get_data().min(axis=3)
sum_mask = nb.Nifti1Image(sum_data, masks[0].affine)
sum_mask.to_filename('./group_min_mask.nii.gz')
