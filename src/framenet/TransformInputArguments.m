function [num_layers, tsfms,variance_threshold,c_start,c_step,c_stop,g_start,g_step,g_stop,filename] = TransformInputArguments(varargin)
% TRANSFORMINPUTARGUMENTS(varargin)
% sample call: TransformInputArguments(2,'curvelet0','curvelet0','curvelet0',1e-10,0,3,12,-12,3,-3)
% Basic reader of the input arguments for the "GO_CRAZY" type of functions. 
% varargin has the following structure: NOTE - not finite, will consider putting everything into structures 
% - number of layers - the first argument, needed to determine how many transformations follow it
% - transformation configuration for each layer - (the #transformations = 1 + #layers)
%               example calls for each supported transformation with case of 2 layers: 
%               NOTE: in these examples transform TYPE is the same in each layer. This in general does not have to hold. 
%               We can specify any transformation we want in any of the layers.
%               2,'swt','db4',3,'s 0 h 0','abs','swt','coif2',4,'s 0 h 0','ReLu','swt','rbio4.4',3,'s 0 h 0','abs'
%               2,'morlet0','morlet0','morlet0'
%               2,'morlet',3,6,'abs','morlet',4,4,'abs','morlet',2,8,'abs'
%               2,'curvelet0','curvelet0','curvelet0'
%               2,'curvelet','abs',32,'fdct_wrapping',0,1,3,8,'curvelet','abs',32,'fdct_usfft',0,1,1,12,'curvelet','abs',32,'fdct_wrapping',0,1,3,16
%               2,'shearlet0','shearlet0','shearlet0'
%               2,'shearlet','abs',64,3,[1 1 2],false,'shearlet','abs',64,3,[2 2 3],false,'shearlet','abs',64,4,[1 1 4 4],false
%       For details on all possible values for different transformations see the corresponding Classes descriptions.
% - variance threshold
% - c range         - c_start, c_step, c_stop: example 0,3,12 -> transforms to vector 0:3:12
% - GAMMA range:    - g_start, g_step, g_stop: example -12,3,-3 -> transforms to vector -12:3:-3
% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016

    num_layers = varargin{1};
    filename = [num2str(num_layers), ' | '];
    ind = 2;
    for ii = 1:num_layers
        switch(varargin{ind})
            case 'RAW'
                tsfms = {'RAW'};
                filename = [filename, varargin{ind}];
                ind = ind + 1;
            case 'swt'
                tsfms{ii,1} = varargin{ind}; % 'swt'
                tsfms{ii,2} = varargin{ind+1}; % filter name
                tsfms{ii,3} = varargin{ind+2}; % number of scales
                tsfms{ii,4} = varargin{ind+3}; % subsampling
                tsfms{ii,5} = varargin{ind+4}; % non-linearity
                filename = [filename, varargin{ind},',',varargin{ind+1},',',num2str(varargin{ind+2}),',',num2str(varargin{ind+3}),',',varargin{ind+4},'; '];
                ind = ind + 5;
            case 'morlet0'
                tsfms{ii,1} = varargin{ind};
                filename = [filename, varargin{ind}];
                ind = ind + 1;
            case 'morlet'
                tsfms{ii,1} = varargin{ind};
                tsfms{ii,2} = varargin{ind+1}; % num_scales
                tsfms{ii,3} = varargin{ind+2}; % num_rotations
                tsfms{ii,4} = varargin{ind+3}; % non_linearity_name
                filename = [filename, varargin{ind},',',num2str(varargin{ind+1}),',',num2str(varargin{ind+2}),',',varargin{ind+3},'; '];
                ind = ind + 4;
            case 'gabor0'
                tsfms{ii,1} = varargin{ind};
                filename = [filename, varargin{ind}];
                ind = ind + 1;
            case 'gabor'
                tsfms{ii,1} = varargin{ind};
                tsfms{ii,2} = varargin{ind+1}; % num_scales
                tsfms{ii,3} = varargin{ind+2}; % num_rotations
                tsfms{ii,4} = varargin{ind+3}; % non_linearity_name
                filename = [filename, varargin{ind},',',num2str(varargin{ind+1}),',',num2str(varargin{ind+2}),',',varargin{ind+3},'; '];
                ind = ind + 4;
            case 'battle-lemarie0'
                tsfms{ii,1} = varargin{ind};
                filename = [filename, varargin{ind}];
                ind = ind + 1;
            case 'battle-lemarie'
                tsfms{ii,1} = varargin{ind};
                tsfms{ii,2} = varargin{ind+1}; % num_scales
                tsfms{ii,3} = varargin{ind+2}; % num_rotations
                tsfms{ii,4} = varargin{ind+3}; % non_linearity_name
                filename = [filename, varargin{ind},',',num2str(varargin{ind+1}),',',num2str(varargin{ind+2}),',',varargin{ind+3},'; '];
                ind = ind + 4;
            case 'curvelet0'
                tsfms{ii,1} = varargin{ind};
                filename = [filename, varargin{ind}];
                ind = ind + 1;
            case 'curvelet'
                tsfms{ii,1} = varargin{ind}; % 'curvelet'
                tsfms{ii,2} = varargin{ind+1}; % non-linearity
                tsfms{ii,3} = varargin{ind+2}; % new_image_size
                tsfms{ii,4} = varargin{ind+3}; % implementation method
                tsfms{ii,5} = varargin{ind+4}; % complex or real
                tsfms{ii,6} = varargin{ind+5}; % finest level type
                tsfms{ii,7} = varargin{ind+6}; % number of scales
                tsfms{ii,8} = varargin{ind+7}; % number of angles for 2nd coarsest scale
                filename = [filename, varargin{ind},',',varargin{ind+1},',',num2str(varargin{ind+2}),',',varargin{ind+3},',',num2str(varargin{ind+4}),...
                    ',',num2str(varargin{ind+5}),',',num2str(varargin{ind+6}),',',num2str(varargin{ind+7}),'; '];
                ind = ind + 8;
            case 'shearlet0'
                tsfms{ii,1} = varargin{ind};
                filename = [filename, varargin{ind}];
                ind = ind + 1;
            case 'shearlet'
                tsfms{ii,1} = varargin{ind}; % 'shearlet'
                tsfms{ii,2} = varargin{ind+1}; % non-linearity
                tsfms{ii,3} = varargin{ind+2}; % filters_configuration_2_use - can be 3,7, or default 7
                tsfms{ii,4} = varargin{ind+3}; % num_scales
                tsfms{ii,5} = varargin{ind+4}; % num_shear_levels - A number containing as many digits as there are scales. num_shears for each scale is determined as x-1
                                               % for example if we want 3 scales with 0 0 2 4 shear levels we have to write 1135
                                               % if we give 0 => num_shear_levels = floor((1:num_scales)/2)
                tsfms{ii,6} = varargin{ind+5}; % compute_full_shearlet_system <- bool
                filename = [filename, varargin{ind},',',varargin{ind+1},',',num2str(varargin{ind+2}),',',num2str(varargin{ind+3}),',',...
                    num2str(varargin{ind+4}),',',num2str(varargin{ind+5}),'; '];
                ind = ind + 6;
        end
    end
    variance_threshold = varargin{ind};
    c_start = varargin{ind + 1};
    c_step = varargin{ind + 2};
    c_stop = varargin{ind + 3};
    g_start = varargin{ind + 4};
    g_step = varargin{ind + 5};
    g_stop = varargin{ind + 6};
    filename = [filename,' | ', num2str(varargin{ind}),' | ',num2str(varargin{ind+1}),':',num2str(varargin{ind+2}),':',num2str(varargin{ind+3}),...
        ' | ',num2str(varargin{ind+4}),':',num2str(varargin{ind+5}),':',num2str(varargin{ind+6})];
end