% Extract patches containing faces from the images in the Caltech 10,000
% Web Faces data base using the Viola Jones face detector (false positives
% are discarded)

% imgpath : path to the folder containing data base images
% gtfile  : path to file containing ground truth data
% outfile : output path

% Michael Tschannen, ETH Zurich, 2016


function extract_faces(imgpath, gtfile, outfile)
    
    display_faces = false;

    % load webfaceIDs and webfaceGT
    load(gtfile);
    imgfiles = dir(imgpath);

    faceDetector = vision.CascadeObjectDetector;

    faceidx = 1;
    valididx = 1;
    
    gt = [];
    bboxes = [];
    ids = [];
    files = [];

    % process every image
    for i = 3:length(imgfiles)
        img = imread(strcat(imgpath,imgfiles(i).name));

        boundboxes = step(faceDetector, img);
        
        % handle multiple faces
        currgt = [];
        while imgfiles(i).name == webfacesIDs{faceidx}
            currmarkers = webfacesGT(faceidx,:);
            currgt = [currgt; currmarkers];
            faceidx = faceidx + 1;
            if faceidx > length(webfacesIDs)
                break
            end
        end
        
        if ~isempty(currgt)
            % remove false positives
            [validgt, validboxes] = get_valid_boxes(boundboxes,currgt);
            if ~isempty(validgt)
                % save bounding boxes of true positives
                files = [files; imgfiles(i).name];
                gt = [gt; validgt];
                bboxes = [bboxes; validboxes];
                ids = [ids; valididx*ones(size(validboxes,1),1)];
                
                valididx = valididx + 1;

                if display_faces
                    fprintf(strcat('Image: ',imgfiles(i).name,', number of faces: ',num2str(size(validgt,1)),'\n'))
                    for j = 1:size(validgt,1)
                        for k = 1:2:7
                            img = insertMarker(img,validgt(j,k:k+1));
                            img = insertObjectAnnotation(img, 'rectangle', validboxes(j,:), 'Face');
                        end
                    end
                    imshow(img)
                    waitforbuttonpress
                end
            end
        end
    end
    
    save(outfile,'ids','gt','bboxes','files');
%     csvwrite(validgtcsvfile,gt);
end

% Check whether box congains ground truth landmarks
function [validgt, validboxes] = get_valid_boxes(bboxes,currgt)
    xmin = min(currgt(:,1:2:7),[],2);
    xmax = max(currgt(:,1:2:7),[],2);
    ymin = min(currgt(:,2:2:8),[],2);
    ymax = max(currgt(:,2:2:8),[],2);
    
    validgt = [];
    validboxes = [];
    
    for i = 1:length(xmin)
        for j = 1:size(bboxes,1)
            if (xmin(i) >= bboxes(j,1) && xmax(i) <= bboxes(j,1) + bboxes(j,3)) && ...
                    (ymin(i) >= bboxes(j,2) && ymax(i) <= bboxes(j,2) + bboxes(j,4))
                validgt = [validgt; currgt(i,:)];
                validboxes = [validboxes; bboxes(j,:)];
            end
        end
    end
end