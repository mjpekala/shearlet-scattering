% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef Wavelet_Transform < Transform
    % WAVELET_TRANSFORM Abstract class
    % All Wavelet tranosformatons derived from it, such as MORLET_Transform
    properties
        filter_num_rows_
        filter_num_columns_
        % Filter bank will be a cell of size 
        % number_of_scales x number_of_rotations which contains all the
        % filters from this filter bank
        psi_filter_bank_
        phi_filter_
        % Filter bank parameters
        num_scales_             % J
        num_rotations_          % R
    end
    
    methods
        
        function wavTsfm = Wavelet_Transform(wavelet_transform_name,num_scales, num_rotations, non_linearity_name)
            wavTsfm = wavTsfm@Transform(wavelet_transform_name,non_linearity_name);
            wavTsfm.filter_num_rows_ = 28;
            wavTsfm.filter_num_columns_ = 28;
            wavTsfm.num_scales_ = num_scales;
            wavTsfm.num_rotations_ = num_rotations;
            wavTsfm.GeneratePsiFilterBank();   
            wavTsfm.GeneratePhiFilter();
        end
        
        function [output_image, propagated_images, propagated_transforms_options] = ApplyTransform(wavTsfm, input_image, current_transform_options, last_layer)
            propagated_images = cell(0,0);
            propagated_transforms_options = cell(0,0);
            input_image = fftshift(fft2(ifftshift(input_image)));
            % Calculate the output image using Phi filter
            if(size(wavTsfm.phi_filter_) > size(input_image))
                error('Wavelet_Transform::ApplyTransform: Filter size larger than input image size');
            else
                [x,y] = size(wavTsfm.phi_filter_);
                output_image = input_image.*wavTsfm.phi_filter_;
                %%%%%% CHECK THIS LINE ONCE MORE
                output_image = fftshift(ifft2(ifftshift(output_image)));
                output_image = wavTsfm.ConvertComplexValuedImage2OutputImage(output_image,'full');
                %%%%%% CHECK THIS LINE ONCE MORE
            end
            if(~last_layer)
                % Calculate propagated images using Psi filter bank
                if(~isempty(current_transform_options))
                    if(strcmp(current_transform_options.transformation_name,wavTsfm.name_))
                        current_scale = current_transform_options.scale_number;
                    end
                else
                    current_scale = wavTsfm.num_scales_;
                end
                num_propagated_transforms = current_scale;
                propagated_images = cell(num_propagated_transforms,wavTsfm.num_rotations_);
                propagated_transforms_options = cell(num_propagated_transforms,wavTsfm.num_rotations_);
                for j=1:current_scale
                    for ir = 1:wavTsfm.num_rotations_
                        if(size(wavTsfm.psi_filter_bank_{j,ir}) > size(input_image))
                            error('Wavelet_Transform::ApplyTransform: Filter size larger than input image size');
                        else
                            [x,y] = size(wavTsfm.psi_filter_bank_{j,ir});
                            propagated_images{j,ir} = input_image.*wavTsfm.psi_filter_bank_{j,ir};       
                            propagated_images{j,ir} = fftshift(ifft2(ifftshift(propagated_images{j,ir})));
                            propagated_images{j,ir} = wavTsfm.NonLinearFunction(propagated_images{j,ir});
                        end
                        propagated_transforms_options{j,ir}.scale_number = j;
                        propagated_transforms_options{j,ir}.rotation_number = ir;
                        propagated_transforms_options{j,ir}.transformation_name = wavTsfm.name_;
                    end
                end     
            end
        end
        
    end
    
    methods (Access = {?MORLET_Transform,?BATTLE_LEMARIE_Transform,?GABOR_Transform})        
        function [xi_x, xi_y] = GenerateGrid(wavTsfm, j, theta)
            scale = 2^(j-1);
            tmp_x = (floor(-wavTsfm.filter_num_rows_/2 + 0.5):floor(wavTsfm.filter_num_rows_/2 - 0.5));
            tmp_y = (floor(-wavTsfm.filter_num_columns_/2 + 0.5):floor(wavTsfm.filter_num_columns_/2 - 0.5));
            tmp_x = tmp_x/max(abs(tmp_x));
            tmp_y = tmp_y/max(abs(tmp_y));
            [xi_x, xi_y] = meshgrid(tmp_x, tmp_y);
            xi_x = xi_x/scale;
            xi_y = xi_y/scale;
            
            xi_x_tmp =  cos(theta)*xi_x + sin(theta)*xi_y;
            xi_y_tmp = -sin(theta)*xi_x + cos(theta)*xi_y;
            
            xi_x = xi_x_tmp;
            xi_y = xi_y_tmp;
        end
    end
    
    methods (Abstract) 
        
        GeneratePsiFilterBank(wavTsfm)
        
        filter = GeneratePsiSingleFilter(wavTsfm, j, theta)
        
        GeneratePhiFilter(wavTsfm)  
        
    end
            
            
%                             propagated_images{j,ir} = input_image([1:(x+mod(x,2))/2 (end-(x-mod(x,2))/2+1):end], ...
%                                 [1:(y+mod(y,2))/2 (end-(y-mod(y,2))/2+1):end]).*wavTsfm.psi_filter_bank_{j,ir};
        
        
    
end