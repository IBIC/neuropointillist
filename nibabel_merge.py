import nibabel as nb

#edit to add so that can loop through array of contrast names
#adjust to make input and output paths make sense

image_files = glob('/Users/tal/Downloads/sim.*p-High.gt.Low.nii.gz')
images = [nb.load(img) for img in image_files]

sum_data = nb.concat_images(images).get_data().sum(axis=3)
sum_img = nb.Nifti1Image(sum_data, images[0].affine)
sum_img.to_filename('/Users/tal/Downloads/image_sum.nii.gz')
