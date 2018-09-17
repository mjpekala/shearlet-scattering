% Sample main script run
%   From the command line run the following command:
%
%   $ matlab -nodisplay -nodesktop -r "simple_reduced_script_run()"
%
%   Run experiment for a scattering tree with 2 layers, with Haar wavelet in every layer
%   and with max pooling with region of size 2x2 pixels and 2 pixels sub-sampling rate between first and second layer, 
%   and with rectified-linear unit as non-linearity.
%
% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016


function simple_reduced_script_run()
% Sample function to show usage of the Generalized Scattering "toolbox"
% The script has VI phases:
% Phase I -     Read in all the input and create all neaded variables, scattering tree configuration and classification parameteres
%               Initialize report output, parallel toolbox (if requested), and LOAD the dataset
% Phase II -    Create Scattering Trees and scatter each sample from training and test datasets
% Phase III  -  Generate feature vectors from Scattering Trees outputs - result are 2 matrices: 
%               one for training samples and the other for test samples. Rows of matrices are samples, columns are features
% Phase IV -    Perform normalization and/or dimensionality reduction. Important note: Throughout the script training and test trees and corresponding 
%               feature vectors are kept in local script variables. A conceptually clearer and more readable solution would be to put each in the
%               Dataset class, but this gives us memory burden. Namely, when passing variables as function arguments, matlab passes them by
%               reference, which is fine. The problem starts when we edit those variables inside functions. MATLAB then copies all the content to 
%               new variable, which we cannot afford when dealing with matrices of size x10GB 
% Phase V -     Classification : First 10-fold cross-validation is performed for each combination of the given parameters for C and gamma; 
%               After that we train a model with the parameters which give us the best cross-validation accuracy using the WHOLE dataset. 
%               In the end we use that model to predicting classes for the test set, and calculate the resulting TEST accuracy (final reported accuracy)
% Phase VI -    Report writing
% 
%
% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016


table_index = 1;
running_function_name = 'simple_reduced_script_run';
num_cpus = 1;
feature_transform_type = '072';
num_features_final = 990;
side_cut = 0; %obsolete
set_type = 1;
num_train_samples = 10000;
num_test_samples = 10000;

num_layers = 2 + 1; % 2 layers, +1 added for purpose of experiments (input image counts as "0-th layer"
transform_name = 'swt';
non_linearity_name = 'ReLu';
filter_name_1 = 'haar';
filter_name_2 = 'haar';
filter_name_3 = 'haar';
pooling_1 = '';
pooling_2 = 'p m 2 2';
pooling_3 = 'p m 2 2';
num_scales = 3;

tsfms = {   transform_name,filter_name_1,num_scales,pooling_1,non_linearity_name;...
            transform_name,filter_name_2,num_scales,pooling_2,non_linearity_name;...
            transform_name,filter_name_3,num_scales,pooling_3,non_linearity_name};
        
features_variance_threshold = 1e-3;
c_start = 3;
c_step = 3;
c_stop = 12;
g_start = -12;
g_step = 3;
g_stop = -3;
filename = 'sample_run ';




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   PHASE I   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialize simulation, load dataset %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(genpath('.'))  % assumes the sample script is in the same folder as the core code

% structure time contains all run times for different parts of the simulation. Used in the end for report
time.start_time = datetime('now');
% Create results (and reports) dir if it does not exist already
results_dir_name = [running_function_name,'/'];
if(~exist(results_dir_name,'dir'))
    mkdir(results_dir_name);
end
% if we are running job on SGE it already writes MATLAB output to a file, so there is no need for this diary
filename = [results_dir_name,num2str(num_train_samples),',',num2str(num_test_samples),' | ',filename,' | ', datestr(time.start_time), '.txt'];
diary(filename);
diary on

% Read the dataset
time.load = tic;
dataset_mnist = Dataset_MNIST(set_type, num_train_samples, num_test_samples);
% Initialize paralel toolbox if requested
if (isempty(gcp('nocreate')) && (num_cpus > 1))
    parpool([2,num_cpus]);
end
time.load = toc(time.load);
fprintf('Loading done in %f seconds\n', (time.load));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  PHASE II   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Do Scattering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time.scattering = tic;

% Build scattering trees for training and test sets and run scattering
if (~isempty(gcp('nocreate')) && (num_cpus > 1))
    parfor i = 1:length(dataset_mnist.train_images_)
        train_scattering_tree_collection{i,1} = ScatteringTree(dataset_mnist.train_images_{i,1},tsfms);
        train_scattering_tree_collection{i,1}.Scatter();
    end
    parfor i = 1:length(dataset_mnist.test_images_)
        test_scattering_trees_collection{i,1} = ScatteringTree(dataset_mnist.test_images_{i,1},tsfms);
        test_scattering_trees_collection{i,1}.Scatter();
    end
else
    fprintf('Scattering training image no.   ');
    train_scattering_tree_collection = ScatteringTree.empty(length(dataset_mnist.train_images_),0);
    for i = 1:length(dataset_mnist.train_images_)
        for j =1:numel(num2str(i-1))
            fprintf('\b');
        end
        fprintf('%d',i);
        train_scattering_tree_collection{i,1} = ScatteringTree(dataset_mnist.train_images_{i,1},tsfms);
        train_scattering_tree_collection{i,1}.Scatter();
    end
    test_scattering_trees_collection = ScatteringTree.empty(length(dataset_mnist.test_images_),0);
    fprintf('\n Scattering test image no.   ');
    for i = 1:length(dataset_mnist.test_images_)
        for j =1:numel(num2str(i-1))
            fprintf('\b');
        end
        fprintf('%d',i);
        test_scattering_trees_collection{i,1} = ScatteringTree(dataset_mnist.test_images_{i,1},tsfms);
        test_scattering_trees_collection{i,1}.Scatter();
    end
end
time.scattering = toc(time.scattering);
fprintf('\n Scattering done in %f seconds\n', (time.scattering));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   PHASE III   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Generate Feature Vectors from Scattering Output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time.scattered_images_2_feature_vectors = tic;
% Generate feature vectors from training and test trees
% Find out size of the resulting feautre vectors for each image in advance to speed up calculations
single_feature_vector_size = size(train_scattering_tree_collection{1,1}.ToFeatures(side_cut),1);
train_feature_vectors = zeros(length(train_scattering_tree_collection),single_feature_vector_size); % initialize to save memory and time
for i = 1:length(train_scattering_tree_collection)
    train_feature_vectors(i,:) = train_scattering_tree_collection{i,1}.ToFeatures(side_cut);
end
clearvars train_scattering_tree_collection  % clear tree sample collection to save memory - NOTE: this sometimes doesn't even work
                                            % since matlab has memory bug on UNIX systems - it clears variables from the workspace
                                            % but does not give back the memory to the system
test_feature_vectors = zeros(length(test_scattering_trees_collection),single_feature_vector_size); % initialize to save memory and time
for i = 1:length(test_scattering_trees_collection)
    test_feature_vectors(i,:) = test_scattering_trees_collection{i,1}.ToFeatures(side_cut);
end
clearvars test_scattering_trees_collection % clear tree sample collection to save memory 

feature_vector_size_before_dimensionality_reduction = size(train_feature_vectors,2); % used for report purpose
fprintf('Feature vector size before dimensionality reduction %d \n', feature_vector_size_before_dimensionality_reduction);
time.scattered_images_2_feature_vectors = toc(time.scattered_images_2_feature_vectors);
fprintf('Feature vector formatting done in %f seconds\n', (time.scattered_images_2_feature_vectors));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   PHASE IV   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% Feature Normalization and/or Dimensionality Reduction %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time.feature_normalization_and_dimensionality_reduction = tic;
if ~isempty(gcp('nocreate'))
    delete(gcp);
end
for i=1:length(feature_transform_type)
    switch(feature_transform_type(i))
        case '0'
            % Remove features which are zero for all samples
            valid_features = max(train_feature_vectors)>0 ;
            train_feature_vectors = train_feature_vectors(:, valid_features);
            test_feature_vectors = test_feature_vectors(:, valid_features);
        case '1'
            % normalize to range [-1,1]
            upper_range_bound = 1;
            lower_range_bound = -1;
            % y = kx+n;
            k = (upper_range_bound - lower_range_bound)./(max(train_feature_vectors) - min(train_feature_vectors)); 
            n = (lower_range_bound*max(train_feature_vectors) - upper_range_bound*min(train_feature_vectors))./(max(train_feature_vectors) - min(train_feature_vectors)); 
            train_feature_vectors = bsxfun(@times, train_feature_vectors,k);
            train_feature_vectors = bsxfun(@plus, train_feature_vectors,n);
            test_feature_vectors = bsxfun(@times, test_feature_vectors,k);
            test_feature_vectors = bsxfun(@plus, test_feature_vectors,n);
        case '2' 
            % normalize to range [0,1]
            upper_range_bound = 1;
            lower_range_bound = 0;
            % y = kx+n;
            k = (upper_range_bound - lower_range_bound)./(max(train_feature_vectors) - min(train_feature_vectors)); 
            n = (lower_range_bound*max(train_feature_vectors) - upper_range_bound*min(train_feature_vectors))./(max(train_feature_vectors) - min(train_feature_vectors)); 
            train_feature_vectors = bsxfun(@times, train_feature_vectors,k);
            train_feature_vectors = bsxfun(@plus, train_feature_vectors,n);
            test_feature_vectors = bsxfun(@times, test_feature_vectors,k);
            test_feature_vectors = bsxfun(@plus, test_feature_vectors,n);
        case '3'
            % normalize every feature column x as:
            % x_new = (x-mu(x))/std(x);
            muS = mean(train_feature_vectors);
            stdS = std(train_feature_vectors);
            train_feature_vectors = bsxfun(@minus, train_feature_vectors,muS);
            train_feature_vectors = bsxfun(@rdivide, train_feature_vectors,stdS);
            test_feature_vectors = bsxfun(@minus, test_feature_vectors,muS);
            test_feature_vectors = bsxfun(@rdivide, test_feature_vectors,stdS);   
        case '4'
            % perform PCA
            pca_basis = pca(train_feature_vectors, 'NumComponents', num_features_final);
            if(num_features_final > size(pca_basis,2))
                fprintf('Num of data points is smaller than desired feature numbers');
            else
                pca_basis = pca_basis(:,1:num_features_final);
            end
            train_feature_vectors = train_feature_vectors*pca_basis;
            test_feature_vectors = test_feature_vectors*pca_basis;
        case '5'
            % Remove Near-zero variance Features - threshold determined from the input arguments - between 1e-10 and 1e-3 if used
            train_features_variance = var(train_feature_vectors, 0, 1);
            train_feature_vectors = train_feature_vectors(:,(train_features_variance > features_variance_threshold));
            test_feature_vectors = test_feature_vectors(:,(train_features_variance > features_variance_threshold));
        case '6'
            % Random projections (random feature selection)
            features_random_indices = randi([1 size(train_feature_vectors,2)],1,num_features_final);
            train_feature_vectors = train_feature_vectors(:,features_random_indices);
            test_feature_vectors = test_feature_vectors(:,features_random_indices);
        case '7'
            % Orthogonal Least Squares
            % Partial Least Squares (case where we look for OLS per class) - if used with parpool, pls_multiclass_v2 can be used
            [train_feature_vectors, test_feature_vectors] = pls_multiclass_v2_noparfor(train_feature_vectors',test_feature_vectors',dataset_mnist.train_labels_',unique(dataset_mnist.train_labels_'),num_features_final/10);
            train_feature_vectors = train_feature_vectors';
            test_feature_vectors = test_feature_vectors';
    end
end
time.feature_normalization_and_dimensionality_reduction = toc(time.feature_normalization_and_dimensionality_reduction);
fprintf('Feature transformation (dim.reduction, selection and normalization) done in %f seconds\n', (time.feature_normalization_and_dimensionality_reduction));




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  PHASE V   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% Classification - cross-validation, test labels prediction %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time.classification = tic;

% Create C and GAMMA parameters grids
log2_c_grid = c_start:c_step:c_stop;  c_grid = 2.^log2_c_grid;
log2_g_grid = g_start:g_step:g_stop;  g_grid = 2.^log2_g_grid;
[c_grid, g_grid] = meshgrid(c_grid,g_grid);
% Initialize parpool again if requested
if (isempty(gcp('nocreate')) && (num_cpus > 1))
    parpool([2,num_cpus]);
end

train_labels = dataset_mnist.train_labels_;
if (~isempty(gcp('nocreate')) && (num_cpus > 1))
    parfor i = 1:numel(c_grid)
        fprintf('====================================================================================\n');
        fprintf('Starting training number: %d, with parameters c=%g, gamma=%g\n',i,c_grid(i),g_grid(i));
        fprintf('====================================================================================\n');
        % 10-fold cross-validation
        libsvm_training_options = sprintf('-v 10 -s 0 -t 2 -m 1000 -c %g -gamma %g', c_grid(i), g_grid(i));
        cross_validation_accuracy(i) = svmtrain(train_labels, train_feature_vectors, libsvm_training_options);
    end
else
    for i = 1:numel(c_grid)
        fprintf('====================================================================================\n');
        fprintf('Starting training number: %d, with parameters c=%g, gamma=%g\n',i,c_grid(i),g_grid(i));
        fprintf('====================================================================================\n');
        % 10-fold cross-validation
        libsvm_training_options = sprintf('-v 10 -s 0 -t 2 -m 1000 -c %g -gamma %g', c_grid(i), g_grid(i));
        cross_validation_accuracy(i) = svmtrain(train_labels, train_feature_vectors, libsvm_training_options);
    end
end

% Select the parameters with the highest cross-validation accuracy and plot contours of the accuracy in the C-GAMMA plain
cross_validation_accuracy = reshape(cross_validation_accuracy, size(c_grid));
figure(7),contour(log2(c_grid),log2(g_grid), cross_validation_accuracy,'ShowText','on'),colorbar;
set(gca,'YDir','reverse');
% Determine C and GAMMA which give the highest cross-validation accuracy
[cross_validation_max_accuracy, cv_max_accuracy_ind] = max(cross_validation_accuracy(:));
[cv_max_accuracy_ind1, cv_max_accuracy_ind2] = ind2sub(size(cross_validation_accuracy),cv_max_accuracy_ind);
c_optimal = c_grid(cv_max_accuracy_ind1,cv_max_accuracy_ind2);
g_optimal = g_grid(cv_max_accuracy_ind1,cv_max_accuracy_ind2);
fprintf('Max CV accuracy is %.3f %%, for gamma = %f and c = %f\n',cross_validation_max_accuracy, g_optimal, c_optimal);

% Train the model for the optimal C and GAMMA using the WHOLE dataset
libsvm_training_options = sprintf('-s 0 -t 2 -m 1000 -c %g -gamma %g', c_optimal, g_optimal);
svm_model = svmtrain(dataset_mnist.train_labels_, train_feature_vectors, libsvm_training_options);

% Prediction on test set labels
test_labels_dummy = ones(length(dataset_mnist.test_labels_),1);
[test_labels_predicted, ~, ~] = svmpredict(test_labels_dummy, test_feature_vectors, svm_model, '');
        
% Calculate prediction ACCURACY on the TEST set
final_test_accuracy = 100*sum(test_labels_predicted == dataset_mnist.test_labels_)/length(test_labels_predicted);
time.classification = toc(time.classification);
fprintf('Classification done in %f seconds\n', (time.classification));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  PHASE VI  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Report writing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print out indices of training and test samples used for the simulation - in the spirit of Reproducible Research
fprintf('trainIndices = ');
indices_string = mat2str(dataset_mnist.train_indices_);
fprintf(indices_string); fprintf('\n');
fprintf('testIndices = ');
indices_string = mat2str(dataset_mnist.test_indices_);
fprintf(indices_string); fprintf('\n');

% Data from the Workspace
time.start_time = datestr(time.start_time);
time
cross_validation_accuracy
log2_c_grid = log2(c_grid)
log2_g_grid = log2(g_grid)

% Print out the results of the analysis
fprintf('Accuracy achieved on the test set is: %.3f %%\n',final_test_accuracy);
fprintf('Max cross-validation accuracy is %.3f %%, for gamma = %f and c = %f\n',max(cross_validation_accuracy(:)), g_optimal, c_optimal);
fprintf('Max cross-validation accuracy is %.3f %%, for indicies : [%d,%d]\n',max(cross_validation_accuracy(:)), cv_max_accuracy_ind1, cv_max_accuracy_ind2);
fprintf('Feature dimension (before dimensionality reduction) is: %d\n', feature_vector_size_before_dimensionality_reduction);
fprintf('Feature dimension (after  dimensionality reduction) is: %d\n', size(train_feature_vectors,2));

c_grid
g_grid

results_filename = [results_dir_name,running_function_name,'_results.txt'];
fileID = fopen(results_filename,'a');
% Final result printing to a file (one line in latex readable format) - ALWAYS done
PrintResultsToFile(fileID,table_index,tsfms,feature_transform_type,num_layers,size(train_feature_vectors,2),...
    feature_vector_size_before_dimensionality_reduction,features_variance_threshold,c_start,c_step,c_stop,g_start,g_step,g_stop,...
    log2_c_grid(cv_max_accuracy_ind1,cv_max_accuracy_ind2),log2_g_grid(cv_max_accuracy_ind1,cv_max_accuracy_ind2),final_test_accuracy,max(cross_validation_accuracy(:)));
fclose(fileID);

diary off



end
