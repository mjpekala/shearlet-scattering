% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef CURVELET_Transform < Transform
    
    properties
        % Possible methods: 'fdct_wrapping' (default) and 'fdct_usfft' 
        implementation_method_
        % Size to which we need to resize the input image (just in the first layer). 
        new_image_size_
        % Type of curvelets used: 0 for complex (default), 1 for real
        complex_or_real_curvelets_
        % In case of fdct_wrapping, there are two possibilities for the coefficients at the finest level: 
        % 1 for curvelets, 2 for wavelets (default)
        finest_level_coefficients_
        % Number of scales including the last coarsest level
        num_scales_ 
        % Number of angles at the 2nd coarsest level: minimum 8, must be multiple of 4.
        num_angles_at_2nd_coarsest_level_   
        % See CurveLAB documentation for more details (in particular help for 'fdct_wrapping' and 'fdct_usfft' functions)
    end
    
    methods
        function crvltTsfm = CURVELET_Transform(non_linearity_name,new_image_size,implementation_method,complex_or_real_curvelets,finest_level_coefficients,num_scales, num_angles_at_2nd_coarsest_level)
            if(nargin < 1) non_linearity_name = 'abs'; end
            crvltTsfm = crvltTsfm@Transform('curvelet',non_linearity_name);
            if(nargin < 2) crvltTsfm.new_image_size_ = 32; else crvltTsfm.new_image_size_ = new_image_size; end
            if(nargin < 3) crvltTsfm.implementation_method_ = 'fdct_wrapping'; else crvltTsfm.implementation_method_ = implementation_method; end
            if(nargin < 4) crvltTsfm.complex_or_real_curvelets_ = 0; else crvltTsfm.complex_or_real_curvelets_ = complex_or_real_curvelets; end
            if(nargin < 5) crvltTsfm.finest_level_coefficients_ = 1; else crvltTsfm.finest_level_coefficients_ = finest_level_coefficients; end
            if(nargin < 6) crvltTsfm.num_scales_ = 0; else crvltTsfm.num_scales_ = num_scales; end
            if(nargin < 7) crvltTsfm.num_angles_at_2nd_coarsest_level_ = 8; else crvltTsfm.num_angles_at_2nd_coarsest_level_ = num_angles_at_2nd_coarsest_level; end
        end
        
        function [output_image, propagated_images, propagated_transforms_options] = ApplyTransform(crvltTsfm, input_image, current_transform_options, last_layer)
            propagated_images = cell(0,0);
            propagated_transforms_options = cell(0,0);
            output_image = [];
%             if(isempty(current_transform_options)) % this happens only in the 0th layer
%                 input_image = imresize(input_image,[crvltTsfm.new_image_size_ crvltTsfm.new_image_size_]);
%             end
            if(min(size(input_image)) > 2 && ~any(isnan(input_image(:))) && crvltTsfm.GetNumScales(input_image)>0)
                % bool value do_only_coarse_scale - if true I have modified fdct_wrapping such that it computes JUST the coarse scale image of the Curvelet transformation
                do_only_coarse_scale = last_layer;
                switch crvltTsfm.implementation_method_
                    case 'fdct_wrapping'
                        curvelet_coefficients = fdct_wrapping(input_image, crvltTsfm.complex_or_real_curvelets_, crvltTsfm.finest_level_coefficients_, ...
                            crvltTsfm.GetNumScales(input_image), crvltTsfm.num_angles_at_2nd_coarsest_level_,do_only_coarse_scale);
                    case 'fdct_usfft'
                        curvelet_coefficients = fdct_usfft(input_image, crvltTsfm.complex_or_real_curvelets_, crvltTsfm.GetNumScales(input_image));
                end
                % Take the scattered (output) image - ConvertComplexValuedImage2OutputImage() function separates real and imaginary parts such that we can create feature for each one of them
                output_image = crvltTsfm.ConvertComplexValuedImage2OutputImage(curvelet_coefficients{1,1}{1,1},'full');
                if(~last_layer)
                    % If not the last layer, take propagated images as well
                    if(~isempty(current_transform_options) && false)
                        if(strcmp(current_transform_options.transformations_name,'curvelet'))
                            current_scale = current_transform_options.scale_number;
                        end
                    else
                        current_scale = crvltTsfm.GetNumScales(input_image);
                    end
                    for i = 1:(min(current_scale,size(curvelet_coefficients,2))-1)
                        for j = 1:size(curvelet_coefficients{1,i+1},2)
                            propagated_images{i,j} = crvltTsfm.NonLinearFunction(curvelet_coefficients{1,i+1}{1,j});
                            propagated_transforms_options{i,j}.scale_number = i;
                            propagated_transforms_options{i,j}.rotation_number = j;
                            propagated_transforms_options{i,j}.transformation_name = crvltTsfm.name_;
                        end
                    end
                end
            end
        end
    end
    methods (Access = private)
        function num_scales = GetNumScales(crvltTsfm,input_image)
            % Get the number of scales to compute for an input image based on it's size, or based on what user specified
            % Since the size of the images in Curvelet transformation is changing, it is safer to specify number of scales to 0,
            % and then the program itself decides which is the right number of scales to take. This number can go to 0 if the image is too small,
            % when the tree is not grown anymore from this node.
            if(crvltTsfm.num_scales_ == 0)
                num_scales = ceil(log2(min(size(input_image))) - 3);
            else
                num_scales = crvltTsfm.num_scales_;
            end
        end
    end
end