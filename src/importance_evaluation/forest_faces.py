# Script to train a random forest regressor for facial landmark detection for the
# feature importance evaluation in Section 6.2 in the paper

# Michael Tschannen, ETH Zurich, 2016

import numpy as np
import random
import pickle

import h5py
from sklearn.ensemble import RandomForestRegressor
from sklearn.ensemble.forest import _generate_unsampled_indices

# datafilestrain : path of the training data file
# outfile        : path of the output file 
# outfileidx     : path of the output file for the indices of the training images
# dmax           : maximum tree depth

def run(datafilestrain, outfile, outfileidx, dmax):
	numtrees = 30
	minsamples = 5
	nmaxfeats = 0.33
	trainfrac = 0.8
	random.seed(10)
	rffile = outfile
	trainidxfile = outfileidx
	numcpu = 15
	
	if not isinstance(dmax, list):
		dmax = [dmax]
	
	numlandmarks = 4
	
	
	f = h5py.File(datafilestrain)
	X = np.array(f.get('X'),dtype=float)
	Y = np.array(f.get('Y'),dtype=float)
	
	npoints = np.size(X,axis=0)
	
	
	trainidx = random.sample(range(0,npoints),int(round(trainfrac*npoints)))
	
	testidx = [i for i in range(npoints) if i not in trainidx]
	
	meanpred = np.mean(Y.take(trainidx, axis=0),axis=0)
	meanpred = np.outer(np.ones(len(testidx)),meanpred)
	meanprederr = np.square(meanpred - Y.take(testidx, axis=0))
	print('MSE for mean predictor:')
	print(np.mean(meanprederr,axis=0))
	
	intraocdists = np.sqrt(np.sum(np.square(Y.take(range(2), axis=1) - Y.take(range(2,4), axis=1)),axis=1))
	
	rfs = []
	
	dopt = 1
	ooberropt = 10e6
	rfs = []
	
	for d in dmax:
		cumerroob = 0
		currrfs = []
		print('Tree depth: '+str(d))
		for i in range(0,2*numlandmarks,2):
			rf = RandomForestRegressor(n_estimators=numtrees, n_jobs=numcpu, max_features=nmaxfeats, \
									max_depth=None, random_state=1, min_samples_leaf=minsamples, oob_score=True)
			rf.fit(X.take(trainidx, axis=0), Y.take(trainidx, axis=0).take(range(i,i+2), axis=1))
			
			# compute OOB predictions
			ntrain = len(trainidx)
			Yoob = np.zeros((ntrain,2))
			noob = np.zeros(ntrain)
			for tree in rf.estimators_:
				unsampled_indices = _generate_unsampled_indices(tree.random_state, ntrain)
				Ytree = tree.predict(X.take(trainidx, axis=0).take(unsampled_indices, axis=0))
				Yoob[unsampled_indices,:] += Ytree
				noob[unsampled_indices] += 1
			
			# compute OOB prediction error
			currerroob = np.sum(np.square(np.divide(Yoob[noob > 0,:],np.outer(noob[noob > 0],np.ones((1,2)))) \
												- (Y.take(trainidx, axis=0)[noob > 0,:]).take(range(i,i+2), axis=1)),axis=1)
			currmeanerroob = np.mean(np.divide(np.sqrt(currerroob),intraocdists.take(trainidx, axis=0))[noob > 0])
			
			print('Mean relative error for OOB prediction, landmark '+str(i/2)+':')
			print(currmeanerroob)
			
			cumerroob += currmeanerroob
			
			currrfs.append(rf)
		
		if cumerroob < ooberropt:
			rfs = currrfs
			dopt = d
	
	for i in range(0,2*numlandmarks,2):
		Ypred = rfs[i/2].predict(X.take(testidx, axis=0))
		err = np.square(Ypred - Y.take(testidx, axis=0).take(range(i,i+2), axis=1))
		print('MSE for RF prediction, landmark '+str(i/2)+':')
		print(np.mean(err,axis=0))
		
		relerr = np.mean(np.divide(np.sqrt(np.sum(err,axis=1)),intraocdists.take(testidx, axis=0)))
		print('Relative error of RF prediction, landmark '+str(i/2)+':')
		print(relerr)
	
	
	
	pfile = open(rffile, 'wb')
	pickle.dump(rfs, pfile)
	pfile.close()
	
	pfile = open(trainidxfile, 'wb')
	pickle.dump(trainidx, pfile)
	pfile.close()





