# Script to train a random forest classifier for handwritten classification for the
# feature importance evaluation in Section 6.2 in the paper

# Michael Tschannen, ETH Zurich, 2016

import numpy as np
import random
import pickle

import h5py
from sklearn.ensemble import RandomForestClassifier

# datafilestrain : path of the training data file
# datafilestest  : path of the test data file
# outfile        : path of the output file for the forest
# dmax           : maximum tree depth

def run(datafiletrain, datafiletest, outfile, dmax):
	numtrees = 30
	minsamples = 1
	nmaxfeats = 0.33
	crit = 'gini'
	rffile = outfile
	numcpu = 8
	
	
	if not isinstance(dmax, list):
		dmax = [dmax]
	
	f = h5py.File(datafiletrain)
	X = np.array(f.get('X'),dtype=float)
	Y = np.ravel(np.array(f.get('Y'),dtype=float))
	
	
	dopt = 1
	ooberropt = 1
	rfopt = []
	
	for d in dmax:
		rf = RandomForestClassifier(n_estimators=numtrees, criterion=crit, n_jobs=numcpu, max_features=nmaxfeats, \
								max_depth=d, random_state=1, min_samples_leaf=minsamples, oob_score=True)
		print('Tree depth: '+str(d))
		print('Start training...')
		rf.fit(X,Y)
		print('OOB error: ')
		print(1-rf.oob_score_)
		
		if 1-rf.oob_score_ < ooberropt:
			dopt = d
			rfopt = rf
		
	
	print('Start testing...')
	f = h5py.File(datafiletest)
	X = np.array(f.get('X'),dtype=float)
	Y = np.ravel(np.array(f.get('Y'),dtype=float))
	print('Test error: ')
	print(str(1-rfopt.score(X,Y)))
	
	
	pfile = open(rffile, 'wb')
	pickle.dump(rfopt, pfile)
	pfile.close()


