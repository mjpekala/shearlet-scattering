% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef ScatteringNode < handle
    % SCATTERINGNODE
    % Objects are nodes of a tree (in fact tree contains only the configurations, as well as the root)
    % It is then left to the nodes to take care of spreading the tree, by pointint to other nodes with children field
    
    properties
        input_image_                     % Input image into the node in layer n. This is scattered image from previous layer.
                                         % The only exception is the root node where this is the original input image.
        scattering_tree_transformations_ % Transformations for each layer (this will in program be just a reference to 
                                         % the field in ScatteringTree Object). This is needed such that all the nodes
                                         % of the tree can be informed what kind of transformation they need to perform
        layer_number_           % Layer number of the node
        transformation_options_ % XXX_Transformation, for the layer in which the node is situated
        output_                 % Output image for the node (after the low-pass filtering)
        children_               % "Pointers" to the children (other ScatteringNode objects) of this node. 
                                % It's number is determined by the number of atoms in the tranosformation_options_ transformation (-1 for the low-pass filter)
    end
    
    methods(Access = public)
        
        function sNode = ScatteringNode(input_image, layer_number, scattering_tree_transformations, transformation_options)
            % Constructor
            sNode.input_image_ = input_image;
            sNode.layer_number_ = layer_number;
            sNode.scattering_tree_transformations_ = scattering_tree_transformations;
            if(layer_number>0)
                sNode.transformation_options_ = transformation_options;
            end
        end
        
    end
    
    methods(Access = public)
    
        function ApplyTransformToInput(Scattering_Node)
            num_layers_total = size(Scattering_Node.scattering_tree_transformations_,1)-1;
            if(num_layers_total > -1)  % -1 using internally to mark 'RAW' case
                % Non-RAW case
                % Apply transform actually does the scattering in each node
                [Scattering_Node.output_, propagated_images, propagated_transformations_options] = ...
                    Scattering_Node.scattering_tree_transformations_{Scattering_Node.layer_number_+1}.ApplyTransform(Scattering_Node.input_image_, Scattering_Node.transformation_options_, Scattering_Node.layer_number_ == num_layers_total);
                if( Scattering_Node.layer_number_ < num_layers_total) % If we are not already in the last layer
                    [children_size_1, children_size_2] = size(propagated_images);
                    Scattering_Node.children_ = cell(children_size_1,children_size_2);
                    for i = 1:children_size_1
                        for j = 1:children_size_2
                            if(~isempty(propagated_images{i,j})) % can happen for curvelets and shearlets where number of shears increases with scale number
                                Scattering_Node.children_{i,j} = ScatteringNode(propagated_images{i,j},Scattering_Node.layer_number_+1, Scattering_Node.scattering_tree_transformations_, propagated_transformations_options{i,j});
                                Scattering_Node.children_{i,j}.ApplyTransformToInput();
                            end
                        end
                    end

                end
            else
                % RAW Case
                % User specified transform option name as 'RAW'. The input
                % image is used at the output without being transformed.
                Scattering_Node.output_ = Scattering_Node.input_image_;
            end
        end
        
        
        function fV = ToFeatures(Scattering_Node,scoff)
            % Transform the output of the node into feature vector. Recursive function.
            fV = [];
            [chSize1, chSize2] = size(Scattering_Node.children_);
            if(chSize1 && chSize2)
                for i = 1:chSize1,
                    for j = 1:chSize2,
                        if(~isempty(Scattering_Node.children_{i,j})) % can happen for curvelets and shearlets where number of shears increases with scale number
                            fV = [fV; Scattering_Node.children_{i,j}.ToFeatures(scoff)];
                        end
                    end
                end
            end
            sz1 = size(Scattering_Node.output_,1);
            sz2 = size(Scattering_Node.output_,2);
            if( (sz1 > 0) && (sz2 > 0) )
                tmp = Scattering_Node.output_((scoff+1):(sz1-scoff),(scoff+1):(sz2-scoff));
                fV = [fV; tmp(:)];
            end
        end
        
        function fV = ToEnergyFeatures(Scattering_Node,side_cut_off)
            % Transform the output of the node into energy based feature vector. 
            % Here we have one feature per image, which is the square root of the sum of squares of all the pixel,
            % i.e., the energy of the image. Recursive function.
            % ONLY DIFFERENT IN ONE (LAST) LINE FROM ToFeatures() method
            fV = [];
            [children_size_1, children_size_2] = size(Scattering_Node.children_);
            if(children_size_1 && children_size_2)
                for i = 1:children_size_1,
                    for j = 1:children_size_2,
                        fV = [fV; Scattering_Node.children_{i,j}.ToEnergyFeatures(side_cut_off)];
                    end
                end
            end
            image_size = size(Scattering_Node.output_,2);
            tmp = Scattering_Node.output_((side_cut_off+1):(image_size-side_cut_off),(side_cut_off+1):(image_size-side_cut_off));
            fV = [fV; sqrt(sum(sum(tmp.^2)))]; 
        end
    
    end
end