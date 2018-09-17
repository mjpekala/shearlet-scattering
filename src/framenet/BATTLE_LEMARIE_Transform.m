% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
classdef BATTLE_LEMARIE_Transform < Wavelet_Transform
    properties

        % parameters characteristic for battle lemariè transform
        beta_ = 0.6;
        battle_lemarie_order_ = 3;
        num_coefficients_to_calculate_sum_ = 30;
    end
    
    methods
        
        function blTsfm = BATTLE_LEMARIE_Transform(num_scales, num_rotations, non_linearity_name)
            blTsfm = blTsfm@Wavelet_Transform('battle_lemarie',num_scales,num_rotations,non_linearity_name);
        end
        
        
    end
    
    methods % ( Access = private )
        
        function GeneratePsiFilterBank(blTsfm)
            for j=1:blTsfm.num_scales_
                for ir = 1:blTsfm.num_rotations_
                    r = ir-1;
                    theta = r*pi/blTsfm.num_rotations_; % for real signals enough to take half of rotations of full circle
                    blTsfm.psi_filter_bank_{j,ir} = blTsfm.GeneratePsiSingleFilter(j,theta);
                end
            end
        end
        
        function filter = GeneratePsiSingleFilter(blTsfm, j, theta)
            [xi_x, xi_y] = blTsfm.GenerateGrid(j, theta); %TODO : check why Lukas generated scale as 2^(j-3)
            r_radius = sqrt(xi_x.^2+xi_y.^2);
            theta_angle = angle(xi_x + 1i*xi_y);
            % generate angular part
            angular_part = (1/2)*(1 + cos((abs(theta_angle)*2*blTsfm.num_rotations_/(2*pi) - (1-blTsfm.beta_)/2)*pi/blTsfm.beta_));
            angular_part((abs(theta_angle)*2*blTsfm.num_rotations_/(2*pi)) >= (1+blTsfm.beta_)/2) = 0; 
            angular_part((abs(theta_angle)*2*blTsfm.num_rotations_/(2*pi)) <= (1+blTsfm.beta_)/2) = 1; 
            angular_part = sqrt(angular_part);
            % generate 1-D Battle-Lemarie mother wavelet in frequency domain 
            k = -blTsfm.num_coefficients_to_calculate_sum_:blTsfm.num_coefficients_to_calculate_sum_;
            r_radius_k_grid = zeros(size(r_radius,1),size(r_radius,2),length(k),3);
            for i=1:length(k)
                r_radius_k_grid(:,:,i,1) = (r_radius + 1 + 2*k(i)).^(-2*2*(blTsfm.battle_lemarie_order_+1));
                r_radius_k_grid(:,:,i,2) = (r_radius + k(i)).^(-2*2*(blTsfm.battle_lemarie_order_+1));
                r_radius_k_grid(:,:,i,3) = (r_radius + 2*k(i)).^(-2*2*(blTsfm.battle_lemarie_order_+1));
            end
            radial_part = (r_radius.^(-2*(blTsfm.battle_lemarie_order_+1))).*...
                sqrt(sum(r_radius_k_grid(:,:,:,1),3)./(sum(r_radius_k_grid(:,:,:,2),3).*sum(r_radius_k_grid(:,:,:,3),3)));
            radial_part = blTsfm.RemoveSingularValues(radial_part);
            % generate final filter by multiplying radial and angular parts
            % factor sqrt(2) is due to the fact that we use only positive rotations
            filter = sqrt(2)*radial_part.*angular_part;
        end
        
        function GeneratePhiFilter(blTsfm)
            j = 1;
            theta = 0;
            [xi_x, xi_y] = blTsfm.GenerateGrid(j, theta); %TODO : check why Lukas generated scale as 2^(j-3)
            r_radius = sqrt(xi_x.^2+xi_y.^2);
            % for phi (low-pass) filter, we don't have angular part
            % generate 1-D Battle-Lemarie mother wavelet in frequency domain 
            k = -blTsfm.num_coefficients_to_calculate_sum_:blTsfm.num_coefficients_to_calculate_sum_;
            r_radius_k_grid = zeros(size(r_radius,1),size(r_radius,2),length(k));
            for i=1:length(k)
                r_radius_k_grid(:,:,i,1) = (r_radius + k(i)).^(-2*2*(blTsfm.battle_lemarie_order_+1));
            end
            radial_part = (r_radius.^(-2*(blTsfm.battle_lemarie_order_+1))).* sum(r_radius_k_grid(:,:,:),3).^(-1/2);
            radial_part = blTsfm.RemoveSingularValues(radial_part);
            % generate final filter by multiplying radial and angular part=1
            % factor sqrt(2) is due to the fact that we use only positive rotations
            blTsfm.phi_filter_ = sqrt(2)*radial_part;
        end
        
        function filter = RemoveSingularValues(~,filter)
        % This function interpolates points where filter values did not converge nicely
            nan_or_inf_indices = find(isnan(filter) | isinf(filter));
            filter(nan_or_inf_indices) = (filter(nan_or_inf_indices+1)+filter(nan_or_inf_indices-1))/2;
        end
        
    end
   
end