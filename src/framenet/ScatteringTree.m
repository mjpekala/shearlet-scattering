% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef ScatteringTree < handle
    % SCATTERINGTREE
    % Configuration holding class - before we scatter an image, we create a tree
    % for it. 
    % ScattreingTree class objects contain following fields:
    % - input_image_            - Usually a 28x28 pixel image for MNIST data
    % - num_layers_             - Number of layers the tree has
    % - layers_transformation_  - Struct containing objects of corresponding transformation classes
    %                             Number of layers transformations is equal to number of layers +1
    %                             Supported transformations: SWT2_Transformation, CURVELET_Transformation, 
    %                             SHEARLET_Transformation, MORLET_transformation.
    % - zeroth_node_            - The initial node, i.e., the root of the tree. 
    %                             Essentially an object of ScatteringNode class. It spans the tree through its children nodes.
    
    properties
       
        input_image_ % tree input
        num_layers_
        layers_transformations_
       
        zeroth_node_
   
    end
    
    methods       
        function sTree = ScatteringTree(input, transformations_for_all_layers)
            % transformations_for_all_layers is the tsfms structure
            sTree.input_image_ = input;
            sTree.BuildLayerTransformations(transformations_for_all_layers);
            sTree.zeroth_node_ = ScatteringNode(sTree.input_image_, 0, sTree.layers_transformations_);
        end

        function Scatter(sTree)
            % Inital function which calls ApplyTransformToInput method of the zeroth node, which
            % later goes recursively through the tree
            sTree.zeroth_node_.ApplyTransformToInput();
        end
        
        function fV = ToFeatures(sTree,side_cut_off)
            if nargin < 2
                side_cut_off = 0;
            end
            fV = sTree.zeroth_node_.ToFeatures(side_cut_off);
        end
        
        function fV = ToEnergyFeatures(sTree,side_cut_off)
            if nargin < 2
                side_cut_off = 0;
            end
            fV = sTree.zeroth_node_.ToEnergyFeatures(side_cut_off);
        end
    end
   
    methods (Access = private) 
        function BuildLayerTransformations(Scattering_Tree,tsfms)
            % Function to initialize tranfsormations for each layer
            Scattering_Tree.layers_transformations_ = {};
            Scattering_Tree.num_layers_ = size(tsfms,1)-1;
            for i = 1:size(tsfms,1)
                switch(tsfms{i,1})
                    case 'swt' 
                        if(size(tsfms,2) > 4)
                            Scattering_Tree.layers_transformations_{i,1} = SWT2_Transform(tsfms{i,2},tsfms{i,3},tsfms{i,5},tsfms{i,4});
                        else
                            Scattering_Tree.layers_transformations_{i,1} = SWT2_Transform(tsfms{i,2},tsfms{i,3},'abs',tsfms{i,4});
                        end
                    case 'morlet0'
                        Scattering_Tree.layers_transformations_{i,1} = MORLET_Transform(3,6,'abs');
                    case 'morlet'
                        Scattering_Tree.layers_transformations_{i,1} = MORLET_Transform(tsfms{i,2},tsfms{i,3},tsfms{i,4});
                    case 'gabor0'
                        Scattering_Tree.layers_transformations_{i,1} = GABOR_Transform(3,6,'abs');
                    case 'gabor'
                        Scattering_Tree.layers_transformations_{i,1} = GABOR_Transform(tsfms{i,2},tsfms{i,3},tsfms{i,4});
                    case 'battle-lemarie0'
                        Scattering_Tree.layers_transformations_{i,1} = BATTLE_LEMARIE_Transform(2,4,'abs');
                    case 'battle-lemarie'
                        Scattering_Tree.layers_transformations_{i,1} = BATTLE_LEMARIE_Transform(tsfms{i,2},tsfms{i,3},tsfms{i,4});
                    case 'curvelet0'
                        Scattering_Tree.layers_transformations_{i,1} = CURVELET_Transform();
                    case 'curvelet'
                        Scattering_Tree.layers_transformations_{i,1} = CURVELET_Transform(tsfms{i,2},tsfms{i,3},tsfms{i,4},tsfms{i,5},tsfms{i,6},tsfms{i,7},tsfms{i,8});
                    case 'shearlet0'
                        Scattering_Tree.layers_transformations_{i,1} = SHEARLET_Transform();
                    case 'shearlet'
                        Scattering_Tree.layers_transformations_{i,1} = SHEARLET_Transform(tsfms{i,2},tsfms{i,3},tsfms{i,4},tsfms{i,5},tsfms{i,6});
                    case 'RAW'
                        Scattering_Tree.num_layers_ = -1;    
                end
            end
        end
       
    end
   
end