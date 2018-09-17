Code to reproduce the experiments in the paper

DISCRETE DEEP FEATURE EXTRACTION: A THEORY AND NEW ARCHITECTURES
----------------------------------------------------------------
by T. Wiatowski, M. Tschannen, A. Stanić, P. Grohs, and H. Bölcskei, Proc. of 
International Conference on Machine Learning (ICML), New York, USA, June 2016.

Please include a reference to this paper if you use the code in your research.


Setting up the feature extractor
--------------------------------
The main toolbox wrapper script is framenet/main.m (take a look inside to see what are 
possible 
input arguments for different network configurations)

For sample runs and different configuration specifications, look into 
sample_multiple_run.m script.

For one single sample run, look into sample_single_run.m script.

simple_reduced_script_run.m contains simple function wrapper with a fixed run 
configuration, and possible diverse dimensionality reduction techniques, 
whereas simple_reduced_script_run.m is similar, but only one type of dimensionality 
reduction is possible, namely OLS, followed by normalization to [0,1] range.

Sample calls for the functions named in this file:

   $ matlab -nodisplay -nodesktop -r "sample_multiple_run(10)"

   $ matlab -nodisplay -nodesktop -r "sample_single_run()"

   $ matlab -nodisplay -nodesktop -r "simple_reduced_script_run()"

   $ matlab -nodisplay -nodesktop -r "simple_fully_reduced_script_run()"

For detailed explanations on what they do, take a look into the corresponding *.m files.

 
NOTE: To be able to run experiments you need MATLAB (2015a) installed and also the third 
party libraries have to be placed in framenet/, and compiled 
on your machine. These include the following:

* LibSVM (essential): download the zip file from 
http://www.csie.ntu.edu.tw/~cjlin/cgi-bin/libsvm.cgi?+http://www.csie.ntu.edu.tw/~cjlin/libsvm+zip
     extract it in the same folder where the rest of the code is, and compile the Matlab
     version of libSVM, by following the instructions from matlab/README file:
                      "On Windows systems, pre-built binary files are already in the 
                      directory '..\windows', so no need to conduct installation. 
    We recommend using make.m on both MATLAB and OCTAVE. Just type 
                      'make' to build 'libsvmread.mex', 'libsvmwrite.mex', 'svmtrain.mex', 
                      and 'svmpredict.mex'.
    On MATLAB or Octave:
                          >> make
 
* ols.m (essential): download the file from 
https://github.com/edouardoyallon/ScatNetLight/blob/master/dimensionality_reduction/ols.m 
into framenet/

* MNIST database: Download
   - t10k-images.idx3-ubyte.gz, t10k-labels.idx1-ubyte.gz, train-images.idx3-ubyte, 
   	 train-labels.idx1-ubyte from
           http://yann.lecun.com/exdb/mnist/
     and move the extracted files to framenet/MNIST_dataset/
   - mnistHelper.zip from 
           http://ufldl.stanford.edu/wiki/resources/mnistHelper.zip
     and move the extracted files loadMNISTImages.m, and loadMNISTLabels.m into framenet/



Handwritten digit classification (Section 6.1)
----------------------------------------------
After the third party software is installed, you can reproduce the results from the paper 
with following two commands (cd into framenet/)

   $ chmod 755 reproduce_results.sh
   $ ./reproduce_results.sh

NOTE: Simulations are not speed nor memory optimized and require large resources (in terms 
of CPU time and RAM memory)



Feature importance evaluation (Section 6.2)
-------------------------------------------
Set up the feature extractor (including all third party code and data sets) as described 
above.
Download the Caltech 10,000 Web Faces dataset from
        http://www.vision.caltech.edu/Image_Datasets/Caltech_10K_WebFaces/
unpack the contents and move the folder Caltech_WebFaces/ to importance_evaluation/
    
In the terminal, cd to the folder "importance_evaluation" and run

    $ sh runmnist.sh
    
for feature importance evaluation in handwritten digit classification, or

    $ sh runfaces.sh
    
for feature importance evaluation in facial landmark detection.

NOTE: The random forest training for facial landmark detection requires roughly 64G of RAM
for default parameters.

