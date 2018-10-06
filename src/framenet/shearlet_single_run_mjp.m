% A modified version of sample_single_run.m, with the difference that we
% use shearlets instead of haar wavelets.
%

% mjp, 2018

%% Setup matlab paths

% MJP: not currently used, but here in case we want to do dimension reduction.
if ~exist('pls_multiclass_v2_1')
    addpath(genpath('.'));
end

% MJP: helper functions for loading MNIST data
if ~exist('loadMNISTImages')
    addpath('../mnist');
end

% MJP: the MNIST dataset itself
if ~exist('t10k-labels-idx1-ubyte', 'file')
    addpath('./MNIST_dataset');
end


% MJP: add shearlab codes to Matlab's path.
if ~exist('SLgetShearletSystem2D')
    addpath(genpath('../ShearLab3Dv11'));
end


%% Specify parameters for MNIST+Shearlet scattering experiment

num_cpus_to_use = 1;  % MJP: I do not have parallel computing toolbox => use one CPU only.


% MNIST parameters
num_train_samples = 5000;   % MJP: for our experiments we only use up to 5k training examples
num_test_samples = 10000;
set_type = 1;               % 1 - get balanced test set, starting from 1st index


% MJP: without doing dimension reduction along the way, it is unwieldy to
%      produce scatterings of depth greater than 2.  To keep our subsequent
%      analysis less complex we therefore only do a depth-2 scattering.
%    
%      This is not a framenet limitation, but more a property of scattering
%      transforms themselves.  Our CHCDW transform has the same
%      limitations.
ss_config = 2;

switch(ss_config)
  case 1
    num_layers = 2;
    pooling_1 = '';
    pooling_2 = 'p m 2 2';       % MJP: taken directy from haar experiment script.
                                 %      I believe this is 2x2 max pooling.
    wavelet_xform = {'shearlet0', 'shearlet0', 'shearlet0'};

  case 2
    % this is basically what we do for Haar
    fprintf('\n           --= ONE LAYER SCATTERING =--\n');
    num_layers = 1;
    pooling_1 = '';
    wavelet_xform = {'shearlet0', 'shearlet0'};
    
  otherwise
    error('unknown config');
end
        

%feature_transform = '072';
feature_transform = '011';   % MJP: specify no dimension reduction; features in [-1,1]

num_features_final = 990;    % MJP: this will not be used since we do no dimension reduction
variance_threshold = 1e-3;   % MJP: this will not be used (no dim. reduction, no SVM).
side_cut = 0;                % MJP: obsolete parameter, according to documentation in main.m

% MJP: SVM parameters.  none of these will be used since we do our own classification analysis.  
% However, if we don't provide them, main() will crash.
c_start = 3;
c_step = 3;
c_end = 12;
g_start = -12;
g_step = 3;
g_end = -3;


%%
warning off % MJP: turn off shearlet warnings.  ShearLab complains
            % about small images (i.e. 33x33) but runs under protest

result = main(1,mfilename,num_cpus_to_use,feature_transform,num_features_final,side_cut,set_type,num_train_samples,num_test_samples,...
    num_layers,...
    %{
    transform_name,filter_name_1,num_scales,pooling_1,non_linearity_name,...
    transform_name,filter_name_2,num_scales,pooling_2,non_linearity_name,...
    transform_name,filter_name_3,num_scales,pooling_3,non_linearity_name,...
    %}
    ... 'shearlet0', 'shearlet0', 'shearlet0',
    wavelet_xform{:}, ...
    variance_threshold,c_start,c_step,c_end,g_start,g_step,g_end);

    
%% Save results for later analysis
fn = sprintf('shearlet_feats_config%d.mat', ss_config);
save(fn, 'result', 'ss_config', '-v7.3');

