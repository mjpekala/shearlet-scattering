% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef MORLET_Transform < Wavelet_Transform
    properties

        % parameters characteristic for morlet transform
        gamma_ = 0.6713
        eta_ = 0.35
        sigma_phi_ = 0.7
        sigma_psi_ = 0.5158
        scaling_psi_ = 0.84
        scaling_overall_ = 1.0
    end
    
    methods
        
        function morTsfm = MORLET_Transform(num_scales, num_rotations, non_linearity_name)
            morTsfm = morTsfm@Wavelet_Transform('morlet',num_scales,num_rotations,non_linearity_name);
        end
        
        
    end
    
    methods % ( Access = private )
        
        function GeneratePsiFilterBank(morTsfm)
            for j=1:morTsfm.num_scales_
                for ir = 1:morTsfm.num_rotations_
                    r = ir-1;
                    theta = r*pi/morTsfm.num_rotations_; % for real signals enough to take half of rotations of full circle
                    morTsfm.psi_filter_bank_{j,ir} = morTsfm.GeneratePsiSingleFilter(j,theta);
                end
            end
        end
        
        function filter = GeneratePsiSingleFilter(morTsfm, j, theta)
            [xi_x, xi_y] = morTsfm.GenerateGrid(j, theta);
            exp_coefficient = -exp(-2*pi^2*morTsfm.sigma_psi_^2*morTsfm.eta_^2);
            filter = exp(-2*pi^2*morTsfm.sigma_psi_^2*((xi_x-morTsfm.eta_).^2 + xi_y.^2/morTsfm.gamma_^2)) ...
                + exp_coefficient*exp(-2*pi^2*morTsfm.sigma_phi_^2*(xi_x.^2 + xi_y.^2));
            scaling = morTsfm.scaling_psi_*morTsfm.scaling_overall_*2*morTsfm.sigma_psi_*sqrt(pi/morTsfm.gamma_)/...
                sqrt(1+exp(-4*pi^2*morTsfm.sigma_psi_^2*morTsfm.eta_.^2)-exp(-6*pi^2*morTsfm.sigma_psi_^2*morTsfm.eta_^2));
            filter = scaling*filter;
            %filter = ifftshift(filter);
        end
        
        function GeneratePhiFilter(morTsfm)
            j = 1;
            theta = 0;
            [xi_x, xi_y] = morTsfm.GenerateGrid(j, theta);
            morTsfm.phi_filter_ = exp(-2*pi^2*morTsfm.sigma_phi_^2*(xi_x.^2 + xi_y.^2));
            scaling = morTsfm.scaling_overall_*2*morTsfm.sigma_phi_*sqrt(pi);
            morTsfm.phi_filter_ = scaling*morTsfm.phi_filter_;
            %morTsfm.phi_filter_ = ifftshift(morTsfm.phi_filter_);
            % if reduceOutputDim ... TODO CHECK THIS OUT IN LUKAS' CODE
        end
        
    end
   
end