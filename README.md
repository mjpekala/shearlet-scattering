# shearlet-scattering
Scattering transforms with shearlet-based filters using the framework of Wiatowski et al.  (called "framenet").


## Overview
This software is a minor modification of the framenet codes made publicly available by T. Wiatowski et al.  The shearlet-based filter configuration did not run out-of-the-box for on my local machine (in part due to my not having the parallel computing toolbox available; note also shearlets were a feature that, while in the code, was not included in their publication so it may have been a work in progress).  

I have also taken the liberty of downloading the software dependencies for framenet and adding them to this repository.  These include Shearlab 3D, MNIST data loading utilities, and a custom implemention of ols dimension reduction.  See the framenet documentation for more details.  I have retained the copyright statements where provided and provided links to the original sources (sometimes implicitly via shell scripts that can be used to download their codes).

## Quick start

1.  *Obtain MNIST*.  This code is designed exclusively (?) for experiments involving MNIST. You will also need the MNIST data set.  There are two scripts I have added in  the [mnist data directory](./src/framenet/MNIST_dataset) which will (a) download MNIST and (b) rename the files to match what the framenet codes expect.  

2.  *Generate shearlet scattering features*.  I (mjp) have created a script [shearlet_single_run_mjp](./src/framenet/shearlet_single_run_mjp.m) that will generate scattering features for a subset of MNIST.  In particular, we generate features only for the subset of the training data set needed for our experiments.  We also to the extent possible use only default parameters from framenet and do not (as of this writing) conduct hyperparameter selection.

3.  *Evaluate performance*.  While framenet can run SVM evaluation, for comparison across wavelet scatterings I created a simple standalone script for evaluating using linear SVMs (which is also used for Morlet and CHCDW wavelets in a separate project).  A copy of the evaluation script is available [here](./src/evaluation/classify_main.m).  Note this requires a local libsvm installation.  With some minor modifications the script could be changed to use Matlab's built-in SVM, if desired.


## Pseudo-comparison of (Scattering Framework / Wavelet Transform) Pairs

Some wavelet/scattering transform framework pairs using "default" parameters (i.e. those similar to results reported in paper, or for similar wavelets).  Note that we have *not* explicitly attempted to optimize any of these hyper-parameters, but rather tried to simply take parameters that were similar to those that have already been published.  Note also that the frameworks may differ in terms of how they pool, lowpass, etc. the wavelet features.

1.  For FrameNet, we partially adopted parameters used with the separable wavelets reported in the B&W publication; however, we are using them with Shearlets, which is included in their software package but not explicitly mentioned/advertised in their publication.
2.  For ScatNet, we use the 6-direction Morlet wavelet akin to what is described in B&M.

Values reported in the table are **error rates**, aggregated across all 10 classes on the MNIST test set (which has 10000 examples).

| MNIST # Train       | FrameNet-m1 | FrameNet-m2 | ScatNet-6-m1  | ScatNet-6-m2 |
|      :---:          |   :---:     |    :---:    |  :---:        |  :---:       |
|    300              |   21.2      |   13.20     |  7.69         | 8.67         |
|    500              |   13.63     |  7.59       |  5.85         | 3.79         |
|    700              |   10.97     |   5.99      |  5.03         | 3.23         |
|    1000             |   10.12     |  5.12       |  4.42         | 2.70         |
|    2000             |   8.27      |  4.07       |  3.08         | 2.03         |
|    5000             |   6.28      |  2.84       |  2.11         | 1.41         |
|  :---:              | :---:       |     :---:   |   :---:       | :---:        |
| Framework           | FrameNet    | FrameNet    |   ScatNet     | ScatNet      |
| SVM                 | linear      | linear      |   linear      | linear       |
| Scattering order    | 1           |   2         |  1            | 2            |
| wavelet             | Shearlet    | Shearlet    |   Morlet      | Morlet       |
| Wavelet Scales      |             |             |   4           |  4           | 
| "Directions"        |             |             |   6           |  6           |
| dim. reduction      | none        | none        |  none         | none         |
|  # dimensions       | 1089        | 9801        |   400         | 3856         |

Notes:
1. FrameNet provides state-of-the art performance (comparable with ScatNet+Morlet-6) for MNIST when using separable wavelets and a full training data set (see their paper).  So we believe the FrameNet architecture & theory is sound; our experiments here are explicitly to explore properties of Shearlet scatterings not to say anything about FrameNet as a whole vs. another scattering architecture.
2.  Similarly, our goal is not to try to get best possible overall performance on MNIST, but to as fairly as possible compare different CDW wavelets in scattering context.  Hence the linear svm and minimal dimension reduction.  Otherwise, interpretation becomes even more difficult than it already is.  We refer reader to FrameNet and ScatNet papers for what is possible when all measures are taken to get best possible results.

## Apples-to-Apples (-ish) Comparison on MNIST

Some attempts at a more balanced wavelet classification comparison by placing wavelets by within a common scattering framework.
In particular, we use a simple scattering tree with the same low-pass filters and no pruning based on energy decreasing paths (aka the "Brute Force Tree" (BFT)).  
The idea here is to enforce more consistency in the wavelet comparison by making the lowpass filter uniform.

| MNIST # Train       | CHCDW-12-a     | CHCDW-12-b       | CHCDW-12-c              |  CHCDW-12-d      |
|      :---:          |   :---:        | :---:            | :---:                   |  :---:           |
|    300              |    11.93       | 11.61            |  14.31                  | 12.59            |
|    500              |   6.59         | 6.73             |   7.61                  |  6.69            |
|    700              |    5.55        |  5.73            |   6.21                  |  5.61            |
|    1000             |     4.91       |   4.9            |   4.91                  |  4.97            |
|    2000             |     3.59       |   3.6            |   3.74                  |   3.68           |
|    5000             |     2.52       |   2.57           |   *                     |   2.50           |
|  :---:              | :---:          |  :---:           |  :---:                  |  :---:           |
| Framework           | BFT            | BFT              |  BFT                    |  BFT             |
| SVM                 | linear         | linear           | linear                  |  linear          |
| Scattering order    |  1             | 1                |  2                      |  2               |
| wavelet             | CHCDW-12       | CHCDW-12         | CHCDW-12                |  CHCDW-12        |
| "Spatial" Dims      | 8x8            |  8x8             |  **4x4**                |  8x8             |
| Wavelet Scales (J)  |  5             |  5               |   5                     |   5              |
| Multi-wavelets (L)  | 3              |  3               |   3                     |   3              |
| "Directions"        | 12             |  12              |   12                    | 12               |
| in-situ DR          | none           | none             |  none                   | max(L)           |
| ex post facto DR    | none           | **SVM-weight**   |  none                   |  none            |
|  # dimensions       | 12288          |  9801            |  46272                  | 23808            |
|                     | (1+3x5)x12x8x8 |                  | (1+3x5+(3x5)^2)x12x4x4  | (1+5+5x5)x12x8x8 |

* = Omitted due to time constraints and high probability of being uninteresting.

1.  Without in-situ dimension reduction (DR) the 8x8x12 CHCDW does not fit into memory on my laptop for m=2 for all of MNIST.
2.  I could address 1 by chunking the data sets but (a) this ripples through all of my code, and (b) it is just not the right approach IMO.
3.  One data point is to take m=2 but reduce the spatial dimensions from 8x8x12 -> 4x4x12.  This trade turns out to be detrimental (see CHCDW-12-c).
4.  The right thing to do is introduce some kind of in-situ dimension reduction, along the lines of pruning frequency decreasing paths as proposed by Mallat.
 This exact technique could be explored; however, given the Haar wavelet it is not likely that the frequency support will be nicely contained anywhere.  It is also unclear whether the frequency support, even if spread all around, shrinks due to local nonlinearity.  This is an open research question.
5.  We do not have time for large open research questions.  Therefore, we will explore a few heuristics for in-situ dimension reduction.  For example, we can collapse the multi-wavelet dimension (e.g. by taking the max over this dimension) as we compute.  We can also try a few different heuristics for pruning nodes from the scattering tree (e.g. by looking at their energy relative to their parent, looking at correlations of children relative to parent and keeping only a few least correlelated children, ideally would be nice to somehow leverage properties of the group B e.g. by collapsing subgroups or something smarter).  We will very rapidly explore only a few of these here.



| MNIST # Train       | Morlet-6-a   | Morlet-6-b  | Morlet-12-a | Morlet-6-c  | Morlet-6-d  |  Morlet-6-e |
|      :---:          | :---:        | :---:       | :---:       | :---:       | :---:       |  :---:      |
|    300              |   9.34       | 10.21       |  11.23      |  10.07      | 9.63        |  6.83       |
|    500              |   4.76       | 5.16        | 5.78        |  5.62       | 5.07        |  3.6        |
|    700              |   4.12       | 4.36        |  5.05       |  4.73       | 4.41        |  2.84       |
|    1000             |   3.35       | 3.61        |   4.01      |  3.99       | 3.74        |  2.38       |
|    2000             |   2.45       | 2.48        |  2.74       | 2.79        | 2.60        |  1.83       |
|    5000             |   1.71       | 1.74        |  1.94       | 1.9         | 1.79        |  1.16       |
|  :---:              |  :---:       |  :---:      | :---:       | :---:       | :---:       |  :---:      |
| Framework           |    BFT       | BFT         | BFT         | BFT         |  BFT        |  BFT        |
| SVM                 |  linear      | linear      | linear      |  linear     | linear      | linear      |
| Scattering order    |   1          | 1           | 1           |  1          |  1          |   **2**     |
| wavelet             |   Morlet     | Morlet      | Morlet      | Morlet      |  Morlet     |  Morlet     |
| "Spatial" Dims      |   8x8        |  8x8        | 8x8         |  **4x4**    |  **16x16**  |  **4x4**    |
| Wavelet Scales (J)  |   4          |  **5**      | 5           |   4         |  4          |  4          |
| Multi-wavelets (L)  |   1          |  1          | 1           |   1         |  1          | 1           |
| "Directions"        |   6          |  6          | **12**      |    6        |   6         |   6         |
| in-situ DR          |  none        | none        | none        | none        | none        | **by J**    |
| ex post facto DR    |  none        |  none       | none        |  none       |  none       |  none       |
|  # dimensions       |   1600       |  1984       | 3904        |  400        | 6400        | 3856        |
|                     |  (1+4x6)x8x8 | (1+5x6)x8x8 | (1+5x12)x8x8| (1+4x6)x4x4 | (1+4x6)x16^2|             |

Some observations:
1. For the 6-direction Morlet wavelet, it doesn't seem to make a huge difference whether we use 4 or 5 scales.
2. For the Morlet wavelet, the 12 direction variant actually seems worse than the 6 direction variant. Perhaps for MNIST we have reached a point of diminishing returns for the number of angles and are just adding difficulty to the subsequent classification problem?   Note this is also consistent with what I had observed for regression with MNIST and Morlet (even though we used global averaging in that experiment)!  Nice that the two at least seem to agree...
3. The added dimensionality (due to 8x8 downsampling?) seems to be providing an advantage relatve to the ScatNet m=1 case.

## Blurred MNIST

Here we investigate the impact of Gaussian blurring on the MNIST classification problem.

### Comparisons across Wavelet and Scattering Frameworks

Note: one has the ability to configure the wavelets in each framework.  Some care should be taken to make these configurations as fair/even as possible.  Currently, defaults for ScatNet were used based on Bruna and Mallat while defaults for FrameNet were loosely based on the provided example that was for a different (non-shearlet) wavelet.

One argument against this table below is that the wavelet configurations are such that the number of dimensions is drastically different.  One could argue that we should either (a) adjust wavelet parameters so that the overall number of dimensions is closer or (b) run some kind of dimension reduction to bring the number of dimensions closer together.  The former is probably cleaner.


| MNIST Blur Table 1  | BLUR-Morlet-6   | BLUR-CHCDW-12   | BLUR-Shearlet   |
|      :---:          |  :---:          | :---:           | :---:           |
|    300              |  31.52          | 27.90           | 31.8            |
|    500              |                 | 19.42           | 25.03           |
|    700              |                 | 16.55           | 21.22           |
|    1000             |  19.05          | 14.05           | 17.77           |
|    2000             |  11.75          |  11.19          | 13.47           |
|    5000             |   8.74          |  8.79           | 10.44           |
|  :---:              |  :---:          |  :---:          | :---:           |
| Framework           |  ScatNet        |  BFT            | FrameNet        |
| SVM                 | linear          | linear          | linear          |
| Scattering order    |    1            |  1              | 1               |
| wavelet             | Morlet          | CHCDW           | Shearlet        |
| "Spatial" Dims      |                 | 8x8             |                 |
| Wavelet Scales (J)  |    4            | 5               |                 |
| Multi-wavelets (L)  |    1            | 3               |                 |
| "Directions"        |    6            | 12              |                 |
| dim. reduction      | none            |  none           | none            |
|  # dimensions       | 400             | 12288           | 1089            |
|                     |                 | (1+3x5)x(12x8x8)|                 |

This next table is for an additional layer of scattering.

| MNIST Blur Table 2  | BLUR-Shearlet   |
|      :---:          |  :---:          |
|    300              |    26.46        |
|    500              |    18.00        |
|    700              |    14.06        |
|    1000             |    11.78        |
|    2000             |    8.49         |
|    5000             |    5.92         |
|  :---:              |  :---:          |
| Framework           |  FrameNet       |
| SVM                 | linear          |
| Scattering order    | 2               |
| wavelet             | Shearlet        |
| "Spatial" Dims      |                 |
| Wavelet Scales (J)  |                 |
| Multi-wavelets (L)  |                 |
| "Directions"        |                 |
| dim. reduction      | none            |
|  # dimensions       | 9801            |



### Extras

| MNIST # Train       | Extra-a        |
|      :---:          |   :---:        |
|    300              |   26.70        |
|    500              |   19.20        |
|    700              |   15.41        |
|    1000             |   13.36        |
|    2000             |   10.40        |
|    5000             |   7.56         |
|  :---:              | :---:          |
| Framework           | BFT            |
| SVM                 | linear         |
| Scattering order    |  1             |
| wavelet             | Morlet         |
| "Spatial" Dims      | 8x8            |
| Wavelet Scales (J)  |  4             |
| Multi-wavelets (L)  | 1              |
| "Directions"        | 6              |
|  # dimensions       | 1600           |  
|                     | (1+4x6)x(8x8)  |


## References

1.  [Framenet Download Link](https://www.nari.ee.ethz.ch/commth/research/downloads/dl_feat_extract.html) (last accessed: Sept. 2018)
2.  Wiatowski et al. [Discrete deep feature extraction: A theory and new architectures](https://www.nari.ee.ethz.ch/commth/pubs/p/ICML2016), 2016.
3.  Bruna & Mallat [Invariant Scattering Convolution Networks](https://www.di.ens.fr/~mallat/papiers/Bruna-Mallat-Pami-Scat.pdf), 2013.
