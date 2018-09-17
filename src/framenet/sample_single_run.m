% Sample main script run
%   From the command line run the following command:
%
%   $ matlab -nodisplay -nodesktop -r "sample_single_run()"
%
%   Run experiment for a scattering tree with 2 layers, with Haar wavelet in every layer
%   and with max pooling with region of size 2x2 pixels and 2 pixels sub-sampling rate between first and second layer, 
%   and with rectified-linear unit as non-linearity.
%
% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016


function sample_single_run()


addpath(genpath('.'));


% Specify the parameters for the simulation

filter_name_1 = 'haar';
filter_name_2 = 'haar';
filter_name_3 = 'haar';
pooling_1 = '';
pooling_2 = 'p m 2 2';
pooling_3 = 'p m 2 2';
num_train_samples = 10000;
num_test_samples = 10000;
            
non_linearity_name = 'ReLu';

num_cpus_to_use = 1;
transform_name = 'swt';
feature_transform = '072';
num_features_final = 990; % 10*num_features_per_class for PLS
variance_threshold = 1e-3;
side_cut = 0;
set_type = 1; % 1 - get balanced test set, starting from 1st index
num_layers = 2+1;
num_scales = 3;
c_start = 3;
c_step = 3;
c_end = 12;
g_start = -12;
g_step = 3;
g_end = -3;

main(1,mfilename,num_cpus_to_use,feature_transform,num_features_final,side_cut,set_type,num_train_samples,num_test_samples,...
    num_layers,...
    transform_name,filter_name_1,num_scales,pooling_1,non_linearity_name,...
    transform_name,filter_name_2,num_scales,pooling_2,non_linearity_name,...
    transform_name,filter_name_3,num_scales,pooling_3,non_linearity_name,...
    variance_threshold,c_start,c_step,c_end,g_start,g_step,g_end);
end
