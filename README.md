# shearlet-scattering
Scattering transforms with shearlet-based filters using the framework of Wiatowski et al.  (called "framenet").


## Overview
This software is a minor modification of the framenet codes made publicly available by T. Wiatowski et al.  The shearlet-based filter configuration did not run out-of-the-box for on my local machine (in part due to my not having the parallel computing toolbox available; note also shearlets were a feature that, while in the code, was not included in their publication so it may have been a work in progress).  

I have also taken the liberty of downloading the software dependencies for framenet and adding them to this repository.  These include Shearlab 3D, MNIST data loading utilities, and a custom implemention of ols dimension reduction.  See the framenet documentation for more details.  I have retained the copyright statements where provided and provided links to the original sources (sometimes implicitly via shell scripts that can be used to download their codes).

## Quick start

1.  *Obtain MNIST*.  This code is designed exclusively (?) for experiments involving MNIST. You will also need the MNIST data set.  There are two scripts I have added in  the [mnist data directory](./src/framenet/MNIST_dataset) which will (a) download MNIST and (b) rename the files to match what the framenet codes expect.  

2.  *Generate shearlet scattering features*.  I (mjp) have created a script [shearlet_single_run_mjp](./src/framenet/shearlet_single_run_mjp.m) that will generate scattering features for a subset of MNIST.  In particular, we generate features only for the subset of the training data set needed for our experiments.  We also to the extent possible use only default parameters from framenet and do not (as of this writing) conduct hyperparameter selection.

3.  *Evaluate performance*.  While framenet can run SVM evaluation, for comparison across wavelet scatterings I created a simple standalone script for evaluating using linear SVMs (which is also used for Morlet and CHCDW wavelets in a separate project).  A copy of the evaluation script is available [here](./src/evaluation/classify_main.m).  Note this requires a local libsvm installation.  With some minor modifications the script could be changed to use Matlab's built-in SVM, if desired.

## Expected results

The results reported below are for the default framenet shearlet configuration ("shearlet0"), a two-layer scattering network configuration similar to that provided by the framenet authors for MNIST with separable wavelets (although I omit dimension reduction and make a few other changes), and and linear SVM.  Note that I do not embark upon hyperparameter search (in part, do to limited time and computational resources) so the results below could possibly be improved upon.  Values reported in the table are *error rates*, aggregated across all 10 classes on the MNIST test set (which has 10000 instances).
Another caveat is that we use MNIST images that are of size 31x31 (framenet default).  These may be on the small side for optimal processing with Shearlab.

The table below also includes MNIST results taken from Bruna & Mallat "Invariant Scattering Convolution Networks," 2013.  Note that these numbers are for a nonlinear SVM and the scattering features had undergone dimension reduction; however, I (mjp) was able to reproduce very similar performance without dimension reduction and with the same linear SVM.  The n=500,700 training example configurations are not reported, hence the n/a values.  I have also included some results from our experiments with Haar-type CDW (joint work with W. Czaja).


| # Training Examples | Shear-BW-m2 | Haar-12-m1 | Haar-12-m1-DR  |
|      :---:          |    :---:    |   :---:    | :---:          |
|    300              |   13.20     |    11.93   | 11.61          |
|    500              |  7.59       |   6.59     | 6.73           |
|    700              |  5.99       |    5.55    |  5.73          |
|    1000             | 5.12        |     4.91   |   4.9          |
|    2000             | 4.07        |     3.59   |   3.6          |
|    5000             |  2.84       |     2.52   |   2.57         |

Some information about these feature sets:

|                | Shear-BW-m2 |  Haar-12-m1 | Haar-12-m1-DR |
|  :---:         |      :---:  |  :---:      |  :---:        |
|  # dims        |  9801       |  12288      |  9801         |
| dim. reduction | none        |  none       | SVM-weight    | 
| scat. depth    | 2           |   1         | 1             | 
| SVM            | linear      |  linear     | linear        | 

The CHCDW-12 dimension size comes from downsampling a 32x32 image by a factor of 4, L=3, and J=log(32):
1. layer 1: 8 * 8 * 12 = 768
2. layer 2: (8*8*12) * (3*log(32)) = 11520

## References

1.  [Framenet Download Link](https://www.nari.ee.ethz.ch/commth/research/downloads/dl_feat_extract.html) (last accessed: Sept. 2018)
2.  Wiatowski et al. [Discrete deep feature extraction: A theory and new architectures](https://www.nari.ee.ethz.ch/commth/pubs/p/ICML2016), 2016.
3.  Bruna & Mallat [Invariant Scattering Convolution Networks](https://www.di.ens.fr/~mallat/papiers/Bruna-Mallat-Pami-Scat.pdf), 2013.
