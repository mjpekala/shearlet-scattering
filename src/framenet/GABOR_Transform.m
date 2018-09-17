% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef GABOR_Transform < Wavelet_Transform
    properties

        % parameters characteristic for gabor transform
        gamma_ = 0.6713
        eta_ = 0.35
        sigma_phi_ = 0.7
        sigma_psi_ = 0.5158
        scaling_psi_ = 0.84
        scaling_overall_ = 1.0
    end
    
    methods
        
        function gbrTsfm = GABOR_Transform(num_scales, num_rotations, non_linearity_name)
            gbrTsfm = gbrTsfm@Wavelet_Transform('gabor',num_scales,num_rotations,non_linearity_name);
        end
        
        
    end
    
    methods % ( Access = private )
        
        function GeneratePsiFilterBank(gbrTsfm)
            for j=1:gbrTsfm.num_scales_
                for ir = 1:gbrTsfm.num_rotations_
                    r = ir-1;
                    theta = r*pi/gbrTsfm.num_rotations_; % for real signals enough to take half of rotations of full circle
                    gbrTsfm.psi_filter_bank_{j,ir} = gbrTsfm.GeneratePsiSingleFilter(j,theta);
                end
            end
        end
        
        function filter = GeneratePsiSingleFilter(gbrTsfm, j, theta)
            [xi_x, xi_y] = gbrTsfm.GenerateGrid(j, theta);
            filter = exp(-2*pi^2*gbrTsfm.sigma_psi_^2*((xi_x-gbrTsfm.eta_).^2 + xi_y.^2/gbrTsfm.gamma_^2));
            scaling = gbrTsfm.scaling_psi_*gbrTsfm.scaling_overall_*2*gbrTsfm.sigma_psi_*sqrt(pi/gbrTsfm.gamma_)/...
                sqrt(1+exp(-4*pi^2*gbrTsfm.sigma_psi_^2*gbrTsfm.eta_.^2)-exp(-6*pi^2*gbrTsfm.sigma_psi_^2*gbrTsfm.eta_^2));
            filter = scaling*filter;
        end
        
        function GeneratePhiFilter(gbrTsfm)
            j = 1;
            theta = 0;
            [xi_x, xi_y] = gbrTsfm.GenerateGrid(j, theta);
            gbrTsfm.phi_filter_ = exp(-2*pi^2*gbrTsfm.sigma_phi_^2*(xi_x.^2 + xi_y.^2));
            scaling = gbrTsfm.scaling_overall_*2*gbrTsfm.sigma_phi_*sqrt(pi);
            gbrTsfm.phi_filter_ = scaling*gbrTsfm.phi_filter_;
        end
        
    end
   
end