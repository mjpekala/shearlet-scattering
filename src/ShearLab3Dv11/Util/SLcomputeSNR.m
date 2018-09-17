function snr = SLcomputeSNR( X,Xnoisy )
%SLCOMPUTESNR Summary of this function goes here
%   Detailed explanation goes here
snr = 10*log10(sum(sum(sum(X.^2)))/sum(sum(sum((X-Xnoisy).^2))));
if isnan(snr)
    snr = Inf;
end
end

%
%  Copyright (c) 2014. Rafael Reisenhofer
%
%  Part of ShearLab3D v1.1
%  Built Mon, 10/11/2014
%  This is Copyrighted Material
%
%  If you use or mention this code in a publication please cite the website www.shearlab.org and the following paper:
%  G. Kutyniok, W.-Q. Lim, R. Reisenhofer
%  ShearLab 3D: Faithful Digital SHearlet Transforms Based on Compactly Supported Shearlets.
%  ACM Trans. Math. Software 42 (2016), Article No.: 5.
