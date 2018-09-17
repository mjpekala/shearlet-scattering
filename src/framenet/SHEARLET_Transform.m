% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef SHEARLET_Transform < Transform
    
    properties
        new_image_size_
        filters_configuration_2_use_ % possible values 3,7,0(default is 7)
        num_scales_
        num_shear_levels_
        compute_full_shearlet_system_
        scale_numbers_of_shearlet_coefficients_
        % See ShearLAB documentation for more details (in particular help for 'fdct_wrapping' and 'fdct_usfft' functions)
    end
    
    methods
        function srltTsfm = SHEARLET_Transform(non_linearity_name,filters_configuration_2_use_,num_scales,num_shear_levels,compute_full_shearlet_system)
            if(nargin < 1) non_linearity_name = 'abs'; end
            %srltTsfm = srltTsfm@Transform('shearlet',non_linearity_name);
            srltTsfm = srltTsfm@Transform('shearlet',non_linearity_name,[]); % mjp
            if(nargin < 3) srltTsfm.num_scales_ = 1; else srltTsfm.num_scales_ = num_scales; end
            if(nargin < 2) srltTsfm.filters_configuration_2_use_ = 7; else srltTsfm.filters_configuration_2_use_ = filters_configuration_2_use_; end
            srltTsfm.CalculateMinimumPossibleImageSize();
            % Determine the number of shear levels
            if(nargin < 4) 
                srltTsfm.num_shear_levels_ = ceil((1:srltTsfm.num_scales_)/2); 
            else
                num_shear_levels = str2num(num_shear_levels);
                if(num_shear_levels == 0)
                    srltTsfm.num_shear_levels_ = floor((1:srltTsfm.num_scales_)/2); 
                else
                    for i = srltTsfm.num_scales_:-1:1
                        srltTsfm.num_shear_levels_(i) = mod(num_shear_levels,10)-1;
                        num_shear_levels = floor(num_shear_levels/10);
                    end
                end
            end
            if(nargin < 5) srltTsfm.compute_full_shearlet_system_ = false; else srltTsfm.compute_full_shearlet_system_ = compute_full_shearlet_system; end
            srltTsfm.ComputeScaleNumbersOfShearletCoefficients();
        end
        
        function [output_image, propagated_images, propagated_transforms_options] = ApplyTransform(srltTsfm, input_image, current_transform_options, last_layer)
            if(~isempty(input_image))
                if(min(size(input_image)) < srltTsfm.new_image_size_) 
                    input_image = imresize(input_image, [srltTsfm.new_image_size_ srltTsfm.new_image_size_]);
                end
                propagated_images = cell(0,0);
                propagated_transforms_options = cell(0,0);
                % do_only_coarse_scale = last_layer; % check how to implement 
                % Generate Shearlet System 
                use_GPU = false;
                shearlet_system = SLgetShearletSystem2D(use_GPU,srltTsfm.new_image_size_,srltTsfm.new_image_size_,srltTsfm.num_scales_,...
                    srltTsfm.num_shear_levels_,srltTsfm.compute_full_shearlet_system_);
                % Perform Shearlet Decomposition
                shearlet_coefficients = SLsheardec2D(input_image,shearlet_system);
                % Take the scattered (output) image
                output_image = shearlet_coefficients(:,:,end);
                if(~last_layer)
                    % If not the last layer, take propagated images as well
                    if(~isempty(current_transform_options))
                        if(strcmp(current_transform_options.transformations_name,'shearlet'))
                            current_scale = current_transform_options.scale_number;
                        end
                    else
                        current_scale = srltTsfm.num_scales_;
                    end
                    scale_counters = ones(1,current_scale);
                    for counter = 1:(size(shearlet_coefficients,3)-1)
                        scale_num_prop_im = srltTsfm.scale_numbers_of_shearlet_coefficients_(counter);
                        if (scale_num_prop_im <= current_scale)
                            shear_num_prop_im = scale_counters(scale_num_prop_im);
                            propagated_images{scale_num_prop_im,shear_num_prop_im} = srltTsfm.NonLinearFunction(shearlet_coefficients(:,:,counter));
                            propagated_transforms_options{scale_num_prop_im,shear_num_prop_im}.scale_number = scale_num_prop_im;
                            propagated_transforms_options{scale_num_prop_im,shear_num_prop_im}.shearing_number = shear_num_prop_im;
                            propagated_transforms_options{scale_num_prop_im,shear_num_prop_im}.transformations_name = srltTsfm.name_;
                            scale_counters(scale_num_prop_im) = shear_num_prop_im + 1;
                        end
                    end
% % %                     counter = 1;
% % %                     for i = 1:current_scale
% % %                         for j = 1:2*(2*2^srltTsfm.num_shear_levels_(i))
% % %                             propagated_images{i,j} = srltTsfm.NonLinearFunction(shearlet_coefficients(:,:,counter));
% % %                             propagated_transforms_options{i,j}.scale_number = i;
% % %                             propagated_transforms_options{i,j}.shearing_number = j;
% % %                             propagated_transforms_options{i,j}.transformation_name = srltTsfm.name_;
% % %                         end
% % %                     end
%                     for counter = 1:(size(shearlet_coefficients,3)-1)
%                             propagated_images{counter} = srltTsfm.NonLinearFunction(shearlet_coefficients(:,:,counter));
%                             propagated_transforms_options{counter}.scale_number = counter;
%                             propagated_transforms_options{counter}.shearing_number = counter;
%                             propagated_transforms_options{counter}.transformation_name = srltTsfm.name_;
%                     end
                end
            end
        end
    end
    methods (Access = private)
        function CalculateMinimumPossibleImageSize(srltTsfm)
            % Comput the minimum size an image has to have to be able to apply Shearlet transform whos number of scales is: srltTsfm.num_scales_
            % 1 scale - 33-7;57-3;89-Default Case available
            % 2 scale - 33-7;57-3;89-Default Case available
            % 3 scale - 73-7;121-3;185-Default Case available
            % 4 scale - 73-8;86-7;121-3;185-Default Case available
            % 5 scale - 153-8;174-7;249-3;377-Default Case available
            switch srltTsfm.filters_configuration_2_use_
                case 0
                    switch srltTsfm.num_scales_
                        case 1
                            srltTsfm.new_image_size_ = 89;
                        case 2
                            srltTsfm.new_image_size_ = 89;
                        case 3
                            srltTsfm.new_image_size_ = 185;
                        case 4
                            srltTsfm.new_image_size_ = 185;
                        case 5
                            srltTsfm.new_image_size_ = 376;
                    end
                case 3
                    switch srltTsfm.num_scales_
                        case 1
                            srltTsfm.new_image_size_ = 57;
                        case 2
                            srltTsfm.new_image_size_ = 57;
                        case 3
                            srltTsfm.new_image_size_ = 121;
                        case 4
                            srltTsfm.new_image_size_ = 121;
                        case 5
                            srltTsfm.new_image_size_ = 249;
                    end
                otherwise
                    switch srltTsfm.num_scales_
                        case 1
                            srltTsfm.new_image_size_ = 33;
                        case 2
                            srltTsfm.new_image_size_ = 33;
                        case 3
                            srltTsfm.new_image_size_ = 73;
                        case 4
                            srltTsfm.new_image_size_ = 73;
                        case 5
                            srltTsfm.new_image_size_ = 153;
                    end
            end
        end
        
        function ComputeScaleNumbersOfShearletCoefficients(srltTsfm)
            srltTsfm.scale_numbers_of_shearlet_coefficients_ = [];
            % Compute for first cone (as generated by Shearlab)
            for i = 1:srltTsfm.num_scales_
                srltTsfm.scale_numbers_of_shearlet_coefficients_ = [srltTsfm.scale_numbers_of_shearlet_coefficients_ i*ones(1,2*2^srltTsfm.num_shear_levels_(i)+1)];
            end
            % Compute for second cone (as generated by Shearlab)
            if srltTsfm.compute_full_shearlet_system_ 
                b = 1;
            else
                b = -1;
            end
            for i = 1:srltTsfm.num_scales_
                srltTsfm.scale_numbers_of_shearlet_coefficients_ = [srltTsfm.scale_numbers_of_shearlet_coefficients_ i*ones(1,2*2^srltTsfm.num_shear_levels_(i)+b)];
            end
        end

    end
end