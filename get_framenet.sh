#!/bin/bash
#
#  Downloads the framenet software produced by researchers from ETH Zurich.
#
#  This script is meant to be run from within this directory only.
#
#  REFERENCE:
#    https://www.nari.ee.ethz.ch/commth/research/downloads/dl_feat_extract.html
#
#  NOTES:
#    1.  This code requires matlab wavelet toolbox!
#    2.  It also requires either the parallel computing toolbox
#        or some small modifcations to the code to not crash 
#        if num_cpus=1 and no toolbox available.
#    3.  To see who is using toolbox licenses:
#        /Applications/MATLAB_R2016a.app//etc/maci64/lmutil lmstat -a -c 27027@aplvlic4
#    4.  To run matlab w/ remote license:
#        MLM_LICENSE_FILE=27027@aplvlic4 matlab &


DIR_NAME=DeepFeatExtractCode_Final

if [ ! -d "$DIR_NAME" ]; then
  echo "Downloading B&W Framework"
  curl -O https://www.nari.ee.ethz.ch/commth/research/downloads/DeepFeatExtractCodeFinal.zip
  unzip DeepFeatExtractCodeFinal.zip
  rm DeepFeatExtractCodeFinal.zip
fi

#-------------------------------------------------------------------------------
# Dependencies
#-------------------------------------------------------------------------------

# OLS
if [ ! -f "$DIR_NAME/framenet/ols.m" ]; then
  echo "Downloading OLS codes"
  curl -O https://github.com/edouardoyallon/ScatNetLight/blob/master/dimensionality_reduction/ols.m
  mv ols.m ./DeepFeatExtractCode_Final/framenet
fi


# MNIST data set.
# Note their code seems to assume slightly different file names...
#
cp ../Data/MNIST/train-images-idx3-ubyte $DIR_NAME/framenet/MNIST_dataset/train-images.idx3-ubyte
cp ../Data/MNIST/train-labels-idx1-ubyte $DIR_NAME/framenet/MNIST_dataset/train-labels.idx1-ubyte
cp ../Data/MNIST/t10k-images-idx3-ubyte  $DIR_NAME/framenet/MNIST_dataset/t10k-images.idx3-ubyte
cp ../Data/MNIST/t10k-labels-idx1-ubyte  $DIR_NAME/framenet/MNIST_dataset/t10k-labels.idx1-ubyte


# scripts for loading MNIST data files
cp ./MNIST/load*.m  $DIR_NAME/framenet/MNIST_dataset
