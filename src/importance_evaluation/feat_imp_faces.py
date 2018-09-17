# Michael Tschannen, ETH Zurich, 2016

import feat_importance_extractor as fe

num_directions = 3
num_scales = [3, 3, 3, 0]
img_sizes = [120*120, 120*120, 60*60, 30*30]

rffile = 'rffaces.pkl'
outnames = ['faces_reye', 'faces_leye', 'faces_nose', 'faces_mouth']

rfs = fe.load_pkl(rffile)

for i in range(len(outnames)):
	print('Landmark: ' + outnames[i])
	fe.unmap_feat_vec_csv(rfs[i],outnames[i],num_directions,num_scales,img_sizes)
