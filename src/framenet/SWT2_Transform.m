% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef SWT2_Transform < Transform
    
    properties
       
        filter_name_
        number_of_scales_
        
    end
    
    methods
        
        function swt2tsfm = SWT2_Transform(filter_name_, number_of_scales, non_linearity_name, pooling) 
            swt2tsfm = swt2tsfm@Transform('swt2',non_linearity_name, pooling);
            swt2tsfm.filter_name_ = filter_name_;
            swt2tsfm.number_of_scales_ = number_of_scales;
        end
        
        function [output_image, propagated_images, propagated_transforms_options] = ApplyTransform(swt2tsfm, input_image, current_transform_options, last_layer)
            
            
            X = input_image;
            % Extend the image to be of size of power of 2
            % Look for the first bigger power of the size of the image
            % extended_image_size = 2^(ceil(log2(size(X,1))));
            % X = wextend('2D','zpd',X,(extended_image_size-size(X,1))/2);
            
            propagated_images = cell(0,0);
            propagated_transforms_options = cell(0,0);
            output_image = zeros(0,0);
            if(min(swt2tsfm.number_of_scales_,floor(log2(size(X,1)))) > 0)
                if(last_layer)

                    % take the last approximation image from swt2_symmetric transform
                    [ca, ~, ~, ~] = swt2_symmetric(X, min(swt2tsfm.number_of_scales_,floor(log2(size(X,1)))), swt2tsfm.filter_name_);
                    output_image = swt2tsfm.OutputPoolingFunction_(ca(:,:,end));
                        % TODO: THOMAS' addition:
                        %subsample_step = 2; % here, every second pixel independent of the bandwith of the low-pass filter
                        % output_image = ca(2^(min(swt2tsfm.number_of_scales_,extended_image_size1)-1):subsample_step:end,2^(min(swt2tsfm.number_of_scales_,extended_image_size1)-1):subsample_step:end,end);
                    propagated_images = cell(0,0);
                    propagated_transforms_options = cell(0,0);
                else
                    % Perform SWT decomposition
                    % of X up to the level swt2tsfm.number_of_scales_ 
                    % using swt2tsfm.filter_name_
                    [ca,chd,cvd,cdd] = swt2_symmetric(X,min(swt2tsfm.number_of_scales_,floor(log2(size(X,1)))), swt2tsfm.filter_name_);

                    output_image = swt2tsfm.OutputPoolingFunction_(ca(:,:,end));
                        % THOMAS' addition:
                        %subsample_step = 2; % here, every second pixel independent of the bandwith of the low-pass filter
                        %output_image = single(ca(2^(min(swt2tsfm.number_of_scales_,extended_image_size1)-1):subsample_step:end,2^(min(swt2tsfm.number_of_scales_,extended_image_size1)-1):subsample_step:end,end));

                    % "freq decreasing paths"
                    if(size(current_transform_options))
                        if(strcmp(current_transform_options.transformation_name,'swt2'))
                            current_scale = current_transform_options.scale_number;
                        end                        
                    else
                        current_scale = 1;
                    end
                    num_propagated_transforms = swt2tsfm.number_of_scales_ - current_scale + 1;
                    propagated_images = cell(num_propagated_transforms, 3);
                    propagated_transforms_options = cell(num_propagated_transforms,3);

                    ind = 1;
                    for k = current_scale:size(chd,3) % swt2tsfm.number_of_scales_
                        % Images coding for level k.
                        % Taking also non-linearity, as required by the
                        % scattering theory.
                        propagated_images{ind,1} = swt2tsfm.PropagatedPoolingFunction_(swt2tsfm.NonLinearFunction(single(chd(:,:,k))));
                        propagated_images{ind,2} = swt2tsfm.PropagatedPoolingFunction_(swt2tsfm.NonLinearFunction(single(cvd(:,:,k))));
                        propagated_images{ind,3} = swt2tsfm.PropagatedPoolingFunction_(swt2tsfm.NonLinearFunction(single(cdd(:,:,k))));
                            % THOMAS' addition:
                            % subsample_step = 2; % here, every second pixel independent of the bandwith of the band-pass filter
                            % pixel_start=subsample_step/2;
                            % %pixel_start=2;
                            % propagated_images{ind,1} = swt2tsfm.NonLinearFunction(single(chd(pixel_start:subsample_step:end,pixel_start:subsample_step:end,k)));
                            % propagated_images{ind,2} = swt2tsfm.NonLinearFunction(single(cvd(pixel_start:subsample_step:end,pixel_start:subsample_step:end,k)));
                            % propagated_images{ind,3} = swt2tsfm.NonLinearFunction(single(cdd(pixel_start:subsample_step:end,pixel_start:subsample_step:end,k)));

                        propagated_transforms_options{ind,1}.direction = 'horizontal';
                        propagated_transforms_options{ind,2}.direction = 'vertical';
                        propagated_transforms_options{ind,3}.direction = 'diagonal';

                        propagated_transforms_options{ind,1}.transformation_name = 'swt2';
                        propagated_transforms_options{ind,2}.transformation_name = 'swt2';
                        propagated_transforms_options{ind,3}.transformation_name = 'swt2';
                        for j = 1:3
                            propagated_transforms_options{ind,j}.scale_number = k;
                        end
                        ind = ind + 1;
                    end
                end
            end
        end
        
        
    end
    
    
end
