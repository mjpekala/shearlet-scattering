% Sample main script runs for set size of 10000 training and test images
% Multiple (16) runs are possible:
%   From the command line run the following command:
%
%   $ matlab -nodisplay -nodesktop -r "sample_multiple_run(run_index)"
%
%   Where run_index can be any integer in [1,16].
%
%   For example, to run experiment for a scattering tree with 2 layers, with Haar wavelet in every layer
%   and with max pooling with region of size 2x2 pixels and 2 pixels sub-sampling rate between first and second layer, 
%   and with rectified-linear unit as non-linearity, run:
%
%   $ matlab -nodisplay -nodesktop -r "sample_multiple_run(10)"
%
% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016



function sample_multiple_run(run_index)
addpath(genpath('.'));



% Specify parameters which can take multiple values
filter_name = {'haar'};
num_train_samples = {10000};
pooling = {'','p s 2 1','p m 2 2','p a 2 2'};
             
non_linearity_name = {'abs','ReLu','tansig','logsig'};

% Generate all combinations to investigate
main_counter = 1;
for i6 = 1:numel(num_train_samples)
    for i5 = 1:numel(pooling)
        for i1 = 1:numel(non_linearity_name)
            for i2 = 1:numel(filter_name)
                for i3 = 1:1
                    for i4 = 1:1
                            main_table{main_counter,1} = non_linearity_name{i1};
                            main_table{main_counter,2} = filter_name{i2};
                            main_table{main_counter,3} = filter_name{i2};
                            main_table{main_counter,4} = filter_name{i2};
                            main_table{main_counter,5} = pooling{i5};
                            main_table{main_counter,6} = num_train_samples{i6};
                            main_counter = main_counter + 1;
                    end
                end
            end
        end
    end
end

indices_left_to_do = 1:size(main_table,1);


% Specify the parameters which are fixed
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
log2_c_grid = c_start:c_step:c_end;  c_grid = 2.^log2_c_grid;
log2_g_grid = g_start:g_step:g_end;  g_grid = 2.^log2_g_grid;
[c_grid, g_grid] = meshgrid(c_grid,g_grid);

c = c_grid(cross_val_par);
g = g_grid(cross_val_par);


% Take the parameters which change from the table
index_2_run = indices_left_to_do(run_index);
non_linearity_name = main_table{index_2_run,1};
filter_name_1 = main_table{index_2_run,2};
filter_name_2 = main_table{index_2_run,3};
filter_name_3 = main_table{index_2_run,4};
pooling_1 = '';
pooling_2 = main_table{index_2_run,5};
pooling_3 = main_table{index_2_run,5};
num_train_samples = main_table{index_2_run,6};
if(num_train_samples > 10000)
    num_test_samples = 10000;
else
    num_test_samples = num_train_samples;
end


% Run simulation
main(index_2_run,mfilename,num_cpus_to_use,feature_transform,num_features_final,side_cut,set_type,num_train_samples,num_test_samples,...
    num_layers,...
    transform_name,filter_name_1,num_scales,pooling_1,non_linearity_name,...
    transform_name,filter_name_2,num_scales,pooling_2,non_linearity_name,...
    transform_name,filter_name_3,num_scales,pooling_3,non_linearity_name,...
    variance_threshold,c_start,c_step,c_end,g_start,g_step,g_end);

end
