% Compute features for the MNIST data set for the feature importance 
% evaluation in Section 6.2 in the paper

% imgtrfile : path of the MNIST training image file
% labtrfile : path of the MNIST training labels file
% imgtefile : path of the MNIST test image file
% labtefile : path of the MNIST test labels file
% trainout  : output path for the training features
% testout   : output path for the test features
% fnetpath  : path of the network code
% dmax      : maximum displacement for the random perturbation

% Michael Tschannen, ETH Zurich, 2016

function compute_features_mnist(imgtrfile, labtrfile, imgtefile, labtefile, trainout, testout, fnetpath, dmax)

    % parameters
    imsize = 28;
    imgperclass = 1000;
    ncpu = 4;

    if nargin < 8
        dmax = 0;
    end
    
    addpath(fnetpath)
    
    if (isempty(gcp('nocreate')))
        parpool('local',ncpu);
    end
    
    % laod images
    imtrain = loadMNISTImages(imgtrfile);
    labtrain = loadMNISTLabels(labtrfile);
    
    selidx = [];
    allidx = 1:size(imtrain,2);
    Y = [];
    
    for i = 0:max(labtrain)
        curridx = allidx(labtrain == i);
        
        selidx = [selidx randsample(curridx,imgperclass)];
        Y = [Y; i*ones(imgperclass,1)];
    end
    
    % compute features for training set
    comp_feats(imtrain(:,selidx), imsize, Y, trainout, dmax);
    
    
    imtest = loadMNISTImages(imgtefile);
    Y = loadMNISTLabels(labtefile);
    
    % compute features for test set
    comp_feats(imtest, imsize, Y, testout, dmax);
    
end

function comp_feats(imgs, imsize, Y, outpath, dmax)

    f = comp_feats_img(imgs(:,1),imsize,dmax);
    
    X = zeros(length(f),size(imgs,2));
    X(:,1) = f;
    
    % process every image
    parfor i = 2:size(imgs,2)
        fprintf('Processing image No %i...\n',i);
        X(:,i) = comp_feats_img(imgs(:,i),imsize,dmax)';
    end
    
    save(outpath,'X','Y','-v7.3');
end

function f = comp_feats_img(img,imsize,dmax)
    if nargin < 3
        dmax = 0;
    end
    
    % randomly displace image if needed
    if dmax > 0
        xs = zeros(imsize + 2*dmax);
        delta = randi([0 2*dmax],2);
        xs((delta(1)+1):(delta(1)+imsize),(delta(2)+1):(delta(2)+imsize)) = reshape(img,imsize,imsize);
    else
        xs = reshape(img,imsize,imsize);
    end
    
    f = comp_feats_inv_exp(xs);
end
