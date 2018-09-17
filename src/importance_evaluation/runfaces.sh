matlab -nodisplay -nodesktop -r "extract_faces('Caltech_WebFaces/', 'webfacesGT.mat', 'webfacesvalidGTboxes.mat'); exit()"
matlab -nodisplay -nodesktop -r "compute_features_faces('webfacesvalidGTboxes.mat', 'Caltech_WebFaces/', 'facedata.mat', 'scales.csv', '../framenet/'); exit()"
python -c "import forest_faces; forest_faces.run('facedata.mat', 'rffaces.pkl', 'trainidxfaces.pkl', 14)"
python feat_imp_faces.py