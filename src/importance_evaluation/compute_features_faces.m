% Compute features for the Caltech 10,000 Web Faces data base for the 
% feature importance evaluation in Section 6.2 in the paper

% GTboxfile   : path to file containing face bounding boxes and ground truth
% imgpath     : path to the folder containing data base images
% datasetfile : output path 
% scalefile   : output path for the scaling factors if the images
% fnetpath    : path of the feature extractor code

% Michael Tschannen, ETH Zurich, 2016

function compute_features_faces(GTboxfile, imgpath, datasetfile, scalefile, fnetpath)
    addpath(fnetpath)
    
    gtdata = load(GTboxfile);
    
    % paramters
    targetsize = 120;
    framescale = 1.1;
    ncpu = 4;
    
    if (isempty(gcp('nocreate')))
        parpool('local',ncpu);
    end
    
    [f, currscale, currgt] = comp_feat(strcat(imgpath,gtdata.files(gtdata.ids(1),:)),gtdata.gt(1,:),gtdata.bboxes(1,:),framescale,targetsize);
    
    X = zeros(length(f),length(gtdata.ids));
    X(:,1) = f';
    Y = zeros(size(gtdata.gt))';
    Y(:,1) = currgt';
    scales = zeros(size(gtdata.gt,1),1);
    scales(1) = currscale;
    
    % compute features for every image
    parfor i = 2:length(gtdata.ids)
        fprintf('Processing image No %i...\n',i);
        [f, currscale, currgt] = comp_feat(strcat(imgpath,gtdata.files(gtdata.ids(i),:)),gtdata.gt(i,:),gtdata.bboxes(i,:),framescale,targetsize);
        X(:,i) = f';
        Y(:,i) = currgt';
        scales(i) = currscale;
    end
    
    save(datasetfile,'X','Y','-v7.3');
    csvwrite(scalefile,scales);    
    
end



function [f, currscale, currgt] = comp_feat(imgfile,gt,bbox,framescale,targetsize)
    img = imread(imgfile);
    % extract patch containing face
    currbox = [bbox(1) - (framescale-1)/2 * bbox(3) ...
        bbox(2) - (framescale-1)/2 * bbox(4) ...
        framescale*bbox(3) framescale*bbox(4)];
    currpatch = imcrop(img, currbox);
    currpatch = imresize(currpatch, [targetsize targetsize]);
    % rescale
    currscale = currbox(3)/targetsize;
    % rescale ground truth coordinates
    currgt = gt;
    currgt(1:2:7) = gt(1:2:7) - bbox(1);
    currgt(2:2:8) = gt(2:2:8) - bbox(2);
    currgt = currgt/currscale;

    if size(currpatch,3) == 3
        currpatch = rgb2gray(currpatch);
    end

    f = comp_feats_inv_exp(currpatch);
end


