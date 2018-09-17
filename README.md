# shearlet-scattering
Scattering transforms with shearlet-based filters. 

## Overview
This is a minor modification of the framenet codes of T. Wiatowski et al.  The shearlet-based filters did not run out-of-the-box for on my local machine.  Also made changes so that the parallel computing toolbox is not required.

   [Download Link](https://www.nari.ee.ethz.ch/commth/research/downloads/dl_feat_extract.html)

(last accessed: September 2018)

I have also taken the liberty of downloading the software dependencies for framenet and adding them to this repository.  These include Shearlab 3D, MNIST data loading utilities, and a custom implemention of ols dimension reduction.  See the framenet documentation for more details.

This code is designed exclusively (?) for experiments involving MNIST. You will also need the MNIST data set.  There are two scripts I have added in  the [mnist data directory](./src/framenet/MNIST_dataset) which will (a) download MNIST and (b) rename the files to match what the framenet codes expect.  This will need to be done 1x before running the [shearlet_single_run_mjp](./src/framenet/shearlet_singe_run_mjp.m) script.
