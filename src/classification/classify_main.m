% CLASSIFY_MAIN  Evaluate shearlet-based scattering transform on MNIST.
%
% Requires that you have already run the shearlet scattering feature extractor.

% mjp, 2018

%% Parameters ========================================================
meta.seed = 1066;
meta.svm_kernel = 'linear';
rng(meta.seed);


%% svm train/test ====================================================

input_fn = fullfile('..', 'framenet', 'shearlet_feats.mat');
output_fn = 'results.mat';

if ~exist(input_fn, 'file')
  error('you must run scattering transform feature extractor first!');
end

load(input_fn, 'result');
train.x = result.train_feature_vectors;
train.y = result.dataset_mnist.train_labels_;
test.x = result.test_feature_vectors;
test.y = result.dataset_mnist.test_labels_;

figure; 
subplot(1,2,1); histogram(train.y); title('train labels');
subplot(1,2,2); histogram(test.y); title('test labels');

return % TEMP

% The framenet codes should have already put features into [-1,1] for us.
assert(-1 <= min(train.x(:)));
assert(max(train.x(:)) <= 1);


svm_info.n_train = [300, 500, 700, 1000, 2000, 5000];
svm_info.acc = nan * ones(size(svm_info.n_train));
svm_info.y_hat = nan * ones(numel(test.y), length(svm_info.n_train));


start_time = tic;

for ii = 1:length(svm_info.n_train)
    rng(meta.seed);
    n_train = svm_info.n_train(ii);

    % note: Here we relied upon framenet to balance the training data.
    %is_train = indices_of_first_n(train.y, n_train/10);

    x_train = train.x(:, 1:n_train);
    y_train = train.y(1:n_train);
   
    fprintf('[%s] Training data has %d examples and %d features\n', ...
        mfilename, size(x_train,1), size(x_train,2));

    % train (+ hyperparameter selection)
    opts = train_libsvm();
    opts.svm_kernel = meta.svm_kernel;
    opts.n_folds = 5;
    opts.max_depth = 0;
    train_result = train_libsvm(x_train, y_train, opts);

    fprintf('[%s] Train accuracy %0.2f\n', mfilename, train_result.acc);

    % == TEST ==
    x_test = test.x;
    y_test = test.y;

    [y_hat, metrics, prob] = svmpredict(y_test, x_test, train_result.model);

    fprintf('-------------------------------------------------------------------\n');
    fprintf('[%s] Test error rate for n=%d: %0.2f (runtime=%0.2f min)\n', mfilename, n_train, 100 - metrics(1), toc(start_time)/60.);
    fprintf('-------------------------------------------------------------------\n');
    svm_info.acc(ii) = metrics(1);
    svm_info.y_hat(:,ii) = y_hat(:);

    C = confusionmat(y_test, y_hat);
    disp(C)
    diag(C) ./ sum(C,2) 
    mean(diag(C) ./ sum(C,2))

    % save results incrementally 
    save(output_fn, 'meta', 'svm_info', 'C', '-v7.3');
end
