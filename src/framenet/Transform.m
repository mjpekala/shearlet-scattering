% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef (Abstract) Transform < handle
    
    properties
        %%%  Name of the transform - 'swt','curvelet','morelet'..
        name_
        
        %%% Name of the non-linearity to use. Possible values:
        %%% 'abs'(default), 'ReLu', tansig','logsig' (agreed with Thomas)
        %%% 'ĥardlim','ĥardlims','radbas','satlin','satlins' 
        non_linearity_name_
        %%% Non-linear function handle..to be applied by the transformation
        NonLinearFunction
        
        %%% Pooling part
        % *pooling_ is a structure which contains options of the pooling operator, such as: name, rate, start pixel, step of sliding window.
        propagated_pooling_
        output_pooling_   % *pooling_.name possibile values: 'subsampling', 'max-pooling', 'average-pooling'
                          %
                          % NOTE: all the rates (to follow) can have be fixed value, or be related to the number of the scale
                          % TODO:
                          % NOTE2: .rate and .region_size have a reserved value '-1', we want to subsample with rate 2^j,
                          %                                                 and '-2' where we subsample with rate (1/2)*2^j
                          %     if *pooling_.name == 'subsampling'
                          %         *pooling_.rate:        determines the rate with which we subsample (in both horizontal and vertical direction)
                          %         *pooling_.start_pixel: integer from set [1..pooling_.rate]
                          %         
                          %         -ISSUE: start_pixel value!!!
                          %           
                          %     else
                          %         *pooling_.region_size: integer determining number of (horizontal and vertical) pixels to which we apply pooling
                          %         *pooling_.step:        size of the step of region we take for pooling (the step of sliding window)
                          %                                if equal to 1, the size of input and output images is the same, else we effectively have 
                          %                                max- or avg-pooling with subsampling (output image is smaller than input image)
                          %
                          %         -ISSUE: how to treat border pixels!!!
                          % 
        % *PoolingFunction is a handle to the actual function which will be used to apply pooling to images
        OutputPoolingFunction_
        PropagatedPoolingFunction_
        
        %%%% Comments on pooling
        %%% http://www.deeplearningbook.org/contents/convnets.html
        % 2016-01-10 9.3 Pooling: +++ "A pooling function replaces the output of the net at a certain location with a summary statistic of the nearby
        %                         outputs. For example, the max pooling operation reports the maximum output within a rectangular neighborhood.
        %                         Other popular pooling functions include the average of a rectangular neighborhood, the L2 norm of a rectangular 
        %                         neighborhood, or a weighted average based on the distance from the central pixel."
        %                         +++ "Pooling over spatial regions produces invariance to translation, but if we pool over the outputs of separately 
        %                         parametrized convolutions, the features can learn which transformations to become invariant to." 
        %                         +++ "Some theoretical work gives guidance to which kinds of pooling one should use in various situations (Boureau, 2010).
        %                         It is also possible to dynamically pool features together, for example, by running a clustering algorithm on the 
        %                         locations of interesting features (Boureau, 2011). This approach yields a different set of pooling regions for every
        %                         image. Another approach is to learn a single pooling structure that is then applied to all images (Jia, 2012)."
        % 2016-01-10 9.5 Variants: +++ "When we refer to convolution in the context of neural networks, we usually actually mean an operation that 
        %                          consists of many applications of convolution in parallel. This is because convolution with a single kernel can only 
        %                          extraxt one kind of feautre, albeit at many spatial locations. Usually we want each layer of our network to extract
        %                          many kinds of features, at many locations."
        %                          +++ "One essential feature of any convolutional network implementation is the ability to implicitly zero-pad the
        %                          input in order to make it wider. Without this feature the width of the representation shrinks by the kernel width-1
        %                          at each layer. Zero padding the input allows us to control the kernel width and the size of the output independently. 
        %                          Without zero padding, we are forced to choose between shrinking the spatial extent of the network rapidly and using 
        %                          small kernels - both scenarios that significantly limit the expressive power of the network."
        
    end
    
    methods
        function tsfm = Transform(name,non_linearity_name,varargin)
            tsfm.name_ = name;
            tsfm.non_linearity_name_ = non_linearity_name;
            switch tsfm.non_linearity_name_
                %%% Non-linearities discussed with Thomas
                case 'absSquare'
                    tsfm.NonLinearFunction = @(x) abs(x).^2; 
                case 'abs'
                    tsfm.NonLinearFunction = @abs ; %abs(real(x)) + 1i*abs(imag(x)); % <- not the same as abs=sqrt((real(x))^2+(imag(x))^2)
                case 'ReLu'
                    tsfm.NonLinearFunction = @(x) max(0,real(x)) + 1i*max(0,imag(x)); 
                case 'tansig' % Hyperbolic tangent
                    tsfm.NonLinearFunction = @(x) tansig(real(x)) + 1i*tansig(imag(x));
                case 'logsig' % Logistic sigmoid
                    tsfm.NonLinearFunction = @(x) logsig(real(x)) - (1/2) + 1i*(logsig(imag(x)) - (1/2)); % TODO: check how to deal with this (-1/2) in complex case-- unclear till now Sept2015 
                    % -(1/2) was added because of Thomas' theory
                %%% Other commonly used non-linearities in NNs
                case 'hardlim'
                    tsfm.NonLinearFunction = @(x) hardlim(real(x)) + 1i*hardlim(imag(x));
                case 'hardlims'
                    tsfm.NonLinearFunction = @(x) hardlims(real(x)) + 1i*hardlims(imag(x));
                case 'radbas'  % exp(-x^2)
                    tsfm.NonLinearFunction = @(x) radbas(real(x)) + 1i*radbas(imag(x));
                case 'satlin'  % ../'''''
                    tsfm.NonLinearFunction = @(x) satlin(real(x)) + 1i*satlin(imag(x));
                case 'satlins'
                    tsfm.NonLinearFunction = @(x) satlins(real(x)) + 1i*satlins(imag(x));
            end
            
            %%%%%%% Read varargin{1} for pooling information - introduced
            %%%%%%% in this way so not to disturbe other Transforms
            %%% Initialize pooling functions to unit functions
            tsfm.PropagatedPoolingFunction_ = @(img) img;
            tsfm.OutputPoolingFunction_     = @(x) x;
            % an example of text is: 'p s 2 1 o s 4 3', meaning that we apply pooling to propagated images by subsampling with rate of 2, 
            % starting from 1st pixel. We apply pooling to output images as well by subsampling with rate of 4, starting from 3rd pixel
            format_spec_pooling = '%s %s %d %d %s %s %d %d';
            if(~isempty(varargin{1}))
                pooling_tmp = textscan(varargin{1},format_spec_pooling);
                for ind = [0 4]
                    if(~isempty(pooling_tmp{ind+1}))
                        switch pooling_tmp{ind+1}{1}
                            case 'p'
                                switch pooling_tmp{ind+2}{1}
                                    case 's' % subsampling
                                        tsfm.propagated_pooling_.name = 'subsampling';
                                        tsfm.propagated_pooling_.rate = pooling_tmp{ind+3};
                                        tsfm.propagated_pooling_.start_pixel = pooling_tmp{ind+4};
                                        tsfm.PropagatedPoolingFunction_ = @tsfm.PropagatedPoolingSubsampling; 
                                    case 'm' % max-pooling
                                        tsfm.propagated_pooling_.name = 'max-pooling';
                                        tsfm.propagated_pooling_.region_size = pooling_tmp{ind+3};
                                        tsfm.propagated_pooling_.step = pooling_tmp{ind+4};      
                                        tsfm.PropagatedPoolingFunction_ = @tsfm.PropagatedMaxPooling;                           
                                    case 'a' % average-pooling
                                        tsfm.propagated_pooling_.name = 'average-pooling';
                                        tsfm.propagated_pooling_.region_size = pooling_tmp{ind+3};
                                        tsfm.propagated_pooling_.step = pooling_tmp{ind+4}; 
                                        tsfm.PropagatedPoolingFunction_ = @tsfm.PropagatedAvgPooling; 
                                end
                            case 'o'
                                switch pooling_tmp{ind+2}{1}
                                    case 's' % subsampling
                                        tsfm.output_pooling_.name = 'subsampling';
                                        tsfm.output_pooling_.rate = pooling_tmp{ind+3};
                                        tsfm.output_pooling_.start_pixel = pooling_tmp{ind+4};
                                        tsfm.OutputPoolingFunction_ = @tsfm.OutputPoolingSubsampling; 
                                    case 'm' % max-pooling
                                        tsfm.output_pooling_.name = 'max-pooling';
                                        tsfm.output_pooling_.region_size = pooling_tmp{ind+3};
                                        tsfm.output_pooling_.step = pooling_tmp{ind+4};      
                                        tsfm.OutputPoolingFunction_ = @tsfm.OutputMaxPooling;                           
                                    case 'a' % average-pooling
                                        tsfm.output_pooling_.name = 'average-pooling';
                                        tsfm.output_pooling_.region_size = pooling_tmp{ind+3};
                                        tsfm.output_pooling_.step = pooling_tmp{ind+4}; 
                                        tsfm.OutputPoolingFunction_ = @tsfm.OutputAvgPooling; 
                                end
                        end
                    end
                end
            end
            
            
            
            
        end
    end
    
    methods (Abstract)
        
        [output_image, propagated_images, propagated_transforms_options] = ApplyTransform(tsfm, input_image, current_transform_options, last_layer)
        
    end
    
    methods
        
        % Pooling by subsampling - General Function
        function img = PropagatedPoolingSubsampling(tsfm,img)
            img = img(tsfm.propagated_pooling_.start_pixel:tsfm.propagated_pooling_.rate:end, tsfm.propagated_pooling_.start_pixel:tsfm.propagated_pooling_.rate:end);
        end
        function img = OutputPoolingSubsampling(tsfm,img)
            img = img(tsfm.output_pooling_.start_pixel:tsfm.output_pooling_.rate:end, tsfm.output_pooling_.start_pixel:tsfm.output_pooling_.rate:end);
        end
        
        % Max-pooling - General Function
        function img_out = PropagatedMaxPooling(tsfm,img_in)
            
            % Extend the image by zero-padding it, to avoid border issues
            [im_in_size_1, im_in_size_2] = size(img_in);
            n_pixels_ext = tsfm.propagated_pooling_.region_size - tsfm.propagated_pooling_.step;
            f_2_n_pixels_ext = ceil(n_pixels_ext/2);
            image_extended = zeros(im_in_size_1 + n_pixels_ext,im_in_size_2 + n_pixels_ext);
            image_extended(f_2_n_pixels_ext+1:f_2_n_pixels_ext+im_in_size_1,f_2_n_pixels_ext+1:f_2_n_pixels_ext+im_in_size_2) = img_in; 
            img_in = image_extended;
            [im_in_size_1, im_in_size_2] = size(img_in);
            
            ind_in_1 = 1;
            ind_out_1 = 1;
            

            while(ind_in_1 + tsfm.propagated_pooling_.region_size-1 <= im_in_size_1)
                end_ind_in_1 = ind_in_1 + tsfm.propagated_pooling_.region_size-1;
                ind_in_2 = 1;
                ind_out_2 = 1;
                while(ind_in_2 + tsfm.propagated_pooling_.region_size-1 <= im_in_size_2)
                    end_ind_in_2 = ind_in_2 + tsfm.propagated_pooling_.region_size-1;
                    img_out(ind_out_1,ind_out_2) = max(max(abs(img_in(ind_in_1:end_ind_in_1,ind_in_2:end_ind_in_2))));
                    ind_in_2 = ind_in_2 + tsfm.propagated_pooling_.step;
                    ind_out_2 = ind_out_2 + 1;
                end
                ind_in_1 = ind_in_1 + tsfm.propagated_pooling_.step;
                ind_out_1 = ind_out_1 + 1;
            end
        end
        function img_out = OutputMaxPooling(tsfm,img_in)
            
            % Extend the image by zero-padding it, to avoid border issues
            [im_in_size_1, im_in_size_2] = size(img_in);
            n_pixels_ext = tsfm.output_pooling_.region_size - tsfm.output_pooling_.step;
            f_2_n_pixels_ext = ceil(n_pixels_ext/2);
            image_extended = zeros(im_in_size_1 + n_pixels_ext,im_in_size_2 + n_pixels_ext);
            image_extended(f_2_n_pixels_ext+1:f_2_n_pixels_ext+im_in_size_1,f_2_n_pixels_ext+1:f_2_n_pixels_ext+im_in_size_2) = img_in; 
            img_in = image_extended;
            [im_in_size_1, im_in_size_2] = size(img_in);
            
            ind_in_1 = 1;
            ind_out_1 = 1;
            

            while(ind_in_1 + tsfm.output_pooling_.region_size-1 <= im_in_size_1)
                ind_in_2 = 1;
                ind_out_2 = 1;
                end_ind_in_1 = ind_in_1 + tsfm.output_pooling_.region_size-1;
                while(ind_in_2 + tsfm.output_pooling_.region_size-1 <= im_in_size_2)
                    end_ind_in_2 = ind_in_2 + tsfm.output_pooling_.region_size-1;
                    img_out(ind_out_1,ind_out_2) = max(max(abs(img_in(ind_in_1:end_ind_in_1,ind_in_2:end_ind_in_2))));
                    ind_in_2 = ind_in_2 + tsfm.output_pooling_.step;
                    ind_out_2 = ind_out_2 + 1;
                end
                ind_in_1 = ind_in_1 + tsfm.output_pooling_.step;
                ind_out_1 = ind_out_1 + 1;
            end
        end
        
        % Avg-pooling - General Function
        function img_out = PropagatedAvgPooling(tsfm,img_in)
            
            % Extend the image by zero-padding it, to avoid border issues
            [im_in_size_1, im_in_size_2] = size(img_in);
            n_pixels_ext = tsfm.propagated_pooling_.region_size - tsfm.propagated_pooling_.step;
            f_2_n_pixels_ext = ceil(n_pixels_ext/2);
            image_extended = zeros(im_in_size_1 + n_pixels_ext,im_in_size_2 + n_pixels_ext);
            image_extended(f_2_n_pixels_ext+1:f_2_n_pixels_ext+im_in_size_1,f_2_n_pixels_ext+1:f_2_n_pixels_ext+im_in_size_2) = img_in; 
            img_in = image_extended;
            [im_in_size_1, im_in_size_2] = size(img_in);
            
            ind_in_1 = 1;
            ind_out_1 = 1;
            

            while(ind_in_1 + tsfm.propagated_pooling_.region_size-1 <= im_in_size_1)
                ind_in_2 = 1;
                ind_out_2 = 1;
                end_ind_in_1 = ind_in_1 + tsfm.propagated_pooling_.region_size-1;
                while(ind_in_2 + tsfm.propagated_pooling_.region_size-1 <= im_in_size_2)
                    end_ind_in_2 = ind_in_2 + tsfm.propagated_pooling_.region_size-1;
                    img_out(ind_out_1,ind_out_2) = mean(mean(img_in(ind_in_1:end_ind_in_1,ind_in_2:end_ind_in_2)));
                    ind_in_2 = ind_in_2 + tsfm.propagated_pooling_.step;
                    ind_out_2 = ind_out_2 + 1;
                end
                ind_in_1 = ind_in_1 + tsfm.propagated_pooling_.step;
                ind_out_1 = ind_out_1 + 1;
            end
        end
        function img_out = OutputAvgPooling(tsfm,img_in)
            
            % Extend the image by zero-padding it, to avoid border issues
            [im_in_size_1, im_in_size_2] = size(img_in);
            n_pixels_ext = tsfm.output_pooling_.region_size - tsfm.output_pooling_.step;
            f_2_n_pixels_ext = ceil(n_pixels_ext/2);
            image_extended = zeros(im_in_size_1 + n_pixels_ext,im_in_size_2 + n_pixels_ext);
            image_extended(f_2_n_pixels_ext+1:f_2_n_pixels_ext+im_in_size_1,f_2_n_pixels_ext+1:f_2_n_pixels_ext+im_in_size_2) = img_in; 
            img_in = image_extended;
            [im_in_size_1, im_in_size_2] = size(img_in);
            
            ind_in_1 = 1;
            ind_out_1 = 1;
            

            while(ind_in_1 + tsfm.output_pooling_.region_size-1 <= im_in_size_1)
                end_ind_in_1 = ind_in_1 + tsfm.output_pooling_.region_size-1;
                ind_in_2 = 1;
                ind_out_2 = 1;
                while(ind_in_2 + tsfm.output_pooling_.region_size-1 <= im_in_size_2)
                    end_ind_in_2 = ind_in_2 + tsfm.output_pooling_.region_size-1;
                    img_out(ind_out_1,ind_out_2) = mean(mean(img_in(ind_in_1:end_ind_in_1,ind_in_2:end_ind_in_2)));
                    ind_in_2 = ind_in_2 + tsfm.output_pooling_.step;
                    ind_out_2 = ind_out_2 + 1;
                end
                ind_in_1 = ind_in_1 + tsfm.output_pooling_.step;
                ind_out_1 = ind_out_1 + 1;
            end
        end
        
        
    end
    
    methods (Access = {?Wavelet_Transform,?CURVELET_Transform})
        function output_image = ConvertComplexValuedImage2OutputImage(~, input_image, give_back_full_image_or_half)
            [sz1, sz2] = size(input_image);
            if(strcmp(give_back_full_image_or_half,'half'))
                sz1 = (sz1+mod(sz1,2))/2;
                sz2 = (sz2+mod(sz2,2))/2;
            end
            output_image = input_image(1:sz1,1:sz2);
            output_image = [real(output_image(:)) imag(output_image(:))]';
            output_image = output_image(:);
        end
    end
end