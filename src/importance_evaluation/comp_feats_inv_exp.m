% Extract features from an image for the feature importance evaluation in 
% Section 6.2 in the paper

% Michael Tschannen, ETH Zurich, 2016

function f = comp_feats_inv_exp(img)
    % network specifications
    tsfms = {...
            'swt','db1',3,'','abs';...       % 0th layer specifications
            'swt','db1',3,'p a 2 2','abs';...            % 1st layer specifications                    
            'swt','db1',3,'p a 2 2','abs';...       % 2nd layer specifications
            'swt','db1',3,'p a 2 2','abs'...       % 3rd layer specifications
            };
        
    st = ScatteringTree(img,tsfms);
    st.Scatter();
    f = st.ToFeatures();
end