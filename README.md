# shearlet-scattering
Scattering transforms with shearlet-based filters. 

## Overview
This is a minor modification of the framenet codes of T. Wiatowski et al.  The shearlet-based filters did not run out-of-the-box for on my local machine.  Also made changes so that the parallel computing toolbox is not required.

   [Download Link](https://www.nari.ee.ethz.ch/commth/research/downloads/dl_feat_extract.html)

(last accessed: September 2018)

I have also taken the liberty of downloading the software dependencies for framenet and adding them to this repository.  These include Shearlab 3D, MNIST data loading utilities, and a custom implemention of ols dimension reduction.  See the framenet documentation for more details.

## Quick start.

1.  Obtain MNIST.  This code is designed exclusively (?) for experiments involving MNIST. You will also need the MNIST data set.  There are two scripts I have added in  the [mnist data directory](./src/framenet/MNIST_dataset) which will (a) download MNIST and (b) rename the files to match what the framenet codes expect.  

2.  Generate shearlet scattering transform features.  I (mjp) have created a script [shearlet_single_run_mjp](./src/framenet/shearlet_single_run_mjp.m) that will generate scattering features for a subset of MNIST.  In particular, we generate features only for the subset of the training data set needed for our experiments.  We also to the extent possible use only default parameters from framenet and do not (as of this writing) conduct hyperparameter selection.

3.  Evaluate performance.  I (mjp) have my own script for evaluating using linear SVMs which is also used for Morlet and CHCDW wavelets.  A copy of the evaluation script is available TODO.  Expected performance is TODO.
