# Michael Tschannen, ETH Zurich, 2016

import feat_importance_extractor as fe

num_directions = 3
num_scales = [3, 3, 3, 0]
img_sizes = [28*28, 28*28, 14*14, 7*7]
rffile = 'rfmnist.pkl'
outname = 'mnist_featimp'
rf = fe.load_pkl(rffile)

fe.unmap_feat_vec_csv(rf,outname,num_directions,num_scales,img_sizes)



img_sizes = [36*36, 36*36, 18*18, 9*9]
rffile = 'rfmnistdisp.pkl'
outname = 'mnist_disp_featimp'
rf = fe.load_pkl(rffile)


fe.unmap_feat_vec_csv(rf,outname,num_directions,num_scales,img_sizes)

