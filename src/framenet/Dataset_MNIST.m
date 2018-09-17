% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef Dataset_MNIST < handle
    % DATASET_MNIST class responsible for loading the initial data, 
    % taking the requested number of samples for training and test data, 
    % and storing the indices of the samples taken for purpose of Reproducible Research
    
    % TODO: maybe add all the remaining fields to the dataset? like scattering tree, featureVectors, etc.
    
    properties
        
        num_train_samples_
        train_images_
        train_labels_
        num_test_samples_
        test_images_
        test_labels_
        set_type_   % can take values 1,2,3:
                    % 1 - get balanced training and test sets, i.e., equal number of samples for each class (=num_train_samples/10)
                    %   if possible. For example in the case where we request close to 60000 training samples 
                    %   we cannot request balanced sets, since there is no enough data. However, user can always specify 
                    %   set_type value of 1, and class itself takes care of what is possible and what not.
                    %   The samples are picked starting from the first index.
                    % 2 - take the first num_train_samples_ training images and num_test_samples test images
                    % 3 - take random num_train_samples_ training images and num_test_samples test images
        
        train_indices_  % store selected indices for report purpose
        test_indices_   % store selected indices for report purpose
        
    end
    
    methods( Access = public )
       
        function ds_mnist = Dataset_MNIST(set_type, num_train_samples, num_test_samples)
            if ~exist('set_type', 'var') set_type = 1; end
            if ~exist('num_train_samples', 'var') num_train_samples = 1000; end
            if ~exist('num_test_samples', 'var') num_test_samples = num_train_samples; end
            ds_mnist.num_train_samples_ = num_train_samples;
            ds_mnist.num_test_samples_  = num_test_samples;
            ds_mnist.set_type_ = set_type;
            ds_mnist.LoadTrainImagesAndLabels();
            ds_mnist.LoadTestImagesAndLabels();
        end
        
    end
    
    methods( Access = private )
        
        function LoadTrainImagesAndLabels(ds)
            mnist_training_images = loadMNISTImages('train-images.idx3-ubyte');
            mnist_training_labels = loadMNISTLabels('train-labels.idx1-ubyte');
            if(ds.num_train_samples_ <= 40000) 
                switch(ds.set_type_)
                    case 1
                        ds.train_indices_ = ds.GetBalancedSet(mnist_training_labels, ds.num_train_samples_);
                    case 2
                        ds.train_indices_ = 1:ds.num_train_samples_;
                    case 3
                       ds.train_indices_ = randi([1 60000],1,ds.num_train_samples_);
                end
            else
                ds.train_indices_ = 1:ds.num_train_samples_;
            end
            % Generate training set
            ds.train_images_ = cell(ds.num_train_samples_,1);
            image_size = sqrt(size(mnist_training_images,1)); % will be 28 always
            for i=1:length(ds.train_indices_)
                ds.train_images_{i} = single(reshape(mnist_training_images(:,ds.train_indices_(i)),image_size,image_size));
            end
            % Take the labels for the corresponding training images
            ds.train_labels_ = mnist_training_labels(ds.train_indices_,1);         
        end
        
        function LoadTestImagesAndLabels(ds)
            mnist_test_images = loadMNISTImages('t10k-images.idx3-ubyte');
            mnist_test_labels = loadMNISTLabels('t10k-labels.idx1-ubyte');
            if(ds.num_test_samples_ <= 5000) 
                switch(ds.set_type_)
                    case 1
                        ds.test_indices_ = ds.GetBalancedSet(mnist_test_labels, ds.num_test_samples_);
                    case 2
                        ds.test_indices_ = 1:ds.num_test_samples_;
                    case 3
                        ds.test_indices_ = randi([1 10000],1,ds.num_test_samples_);
                end
            else
                ds.test_indices_ = 1:ds.num_test_samples_;
            end
            % Generate test set
            ds.test_images_ = cell(ds.num_test_samples_,1);
            image_size = sqrt(size(mnist_test_images,1)); % will be 28 always
            for i=1:length(ds.test_indices_)
                ds.test_images_{i} = single(reshape(mnist_test_images(:,ds.test_indices_(i)),image_size,image_size));
            end
            % Take the labels for the corresponding testing images
            ds.test_labels_ = mnist_test_labels(ds.test_indices_,1);         
        end
        
        function indices = GetBalancedSet(ds,labels, num_samples)
            counter_images_found = 0;
            ind = 1;
            num_elements_for_current_class = zeros(10,1);
            num_elements_per_class_final = num_samples/10;
            indices = zeros(num_samples,1);
            while(counter_images_found < num_samples)
                if(num_elements_for_current_class(labels(ind)+1) < num_elements_per_class_final)
                    indices(counter_images_found+1,1) = ind;
                    counter_images_found = counter_images_found + 1;
                    num_elements_for_current_class(labels(ind)+1) = num_elements_for_current_class(labels(ind)+1) + 1;
                end
                ind = ind + 1;
            end
        end
        
    end
    
end
    
