function [movie_out, U, V] = denoisingSVD(movie_in, varargin)
% Denoising the movie by performing truncating SVD
%
% SYNTAX:
% movie_out = denoisingSVD(movie_in); % automatically determine the rank
% movie_out = denoisingSVD(movie_in, 'rank', 10); % specify the rank
% movie_out = denoisingSVD(movie_in, 'removeLowSNR', true); 
% movie_out = denoisingSVD(movie_in, 'removeLowSNR', true, 'snrlevel', 5); % specify the rank
%
% INPUTS:
% - movie_in - input noisy movie, size [m x n x t]
%
% OUTPUTS:
% - movie_out - denoised movie, same dimension as the input
% - U - the decomposed spatial modes
% - V - the decomposed temporal modes
%
% OPTIONS:
% - 'rank': the rank number to be kept for the SVD decomposation, otherwise
%           it will be determined automatically by performing autocorrelations.
%
% - 'removeLowSNR': remove components having low signal-to-noise ratio
%
% HISTORY
% - 2020-05-29 23:12:60 - created by Jizhou Li (hijizhou@gmail.com)
%
% ISSUES
% #1 - 
%
% TODO
% *1 - more options for the function getRankIndex.
% *2 - band-pass filtering 


% CONSTANTS (never change, use OPTIONS instead)
DEBUG_THIS_FILE=false;
FUNCTION_AUTHOR='Jizhou Li (hijizhou@gmail.com)';

%% OPTIONS 
options.author=FUNCTION_AUTHOR;

options.BandPass=false; % perform bandpass filtering of the images first
options.BandPx=[0.05,5]; % spatial band expressed in pixels, input parameters to filters.BandPass2D function [options.BandPx(1)pass_cutoff,highpass_cutoff]
options.rank = -1; % by default, automatically choose the rank number
options.removeLowSNR = false;
options.snrlevel = 2;

%% VARIABLE CHECK 

if nargin>=3
options=imported.biafra.getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

if options.BandPass
%movie_in = BandPass3D(stack,spatial_high,spatial_low,temporal_high);
end


[nx, ny, nz] = size(movie_in);
funReshape = @(x) reshape(double(x),[],nz,1);
funReshapeBack = @(x, nt) reshape(x, nx, ny, nt);

V2d = funReshape(movie_in);
[U,S,V] = svd(V2d,'econ');
Vt=V';

rankindx = getRankIndex(Vt);

realindex = find(rankindx==1);
Usub = U(:,realindex);
Ssub = S(realindex,realindex);
Vsub = Ssub*Vt(realindex,:);

if options.removeLowSNR
    PChigh = (std(Vsub,[],2)./getNoiseLevel(Vsub) > options.snrlevel);
    Vsub = Vsub(PChigh,:);
    Usub  = Usub(:,PChigh);
end

movie_out=funReshapeBack(Usub*Vsub, nz);
U =funReshapeBack(Usub, size(Usub,2));
V = Vsub;

end

function level = getNoiseLevel(Vt)
[m,n] = size(Vt);
level=zeros(m,1);
range_ff=[0.25,0.5];

for i = 1:m
    [Pxx,ff] = pwelch(Vt(i,:),hanning(200),200/2,200,1,'onesided');
    Pxx_ind = Pxx(ff > range_ff(1) & ff < range_ff(2));
    level(i)=sqrt(exp(mean(log(Pxx_ind/2))));
end
end


function rankindx = getRankIndex(Vt, varargin)
% choose the rank number by  identifying the noise floor and truncating principal components representing nois
% see Mitra PP, Pesaran B, Biophys J. 1999 Feb; 76(2):691-708. and PCA/ICA
% paper: Mukamel, Eran A., Axel Nimmerjahn, and Mark J. Schnitzer. "Automated analysis of cellular signals from large-scale calcium imaging data." Neuron 63.6 (2009): 747-760.

[mn, t] = size(Vt);

% generating random variables to compute mean thresholding for auto
% covariance of additive Gaussian noise
n = 3000;
factor = 1;
confidence = 0.99;
maxlag = 5;

for ni=1:n
    rnd_data = randn(t,1);
    covRandt = autocorr(rnd_data, maxlag);
    covRand(ni) = mean(covRandt);
end

% mean confidence interval (CI)
funCI = @(x, confidence, factor) icdf(makedist('Normal','mu',mean(x),'sigma',std(x)),confidence)*factor;
meanvalue = funCI(covRand, confidence, factor);

rankindx = zeros(mn, 1);

for vi = 1:mn
    Vti = Vt(vi, :);
    Vti = (Vti - mean(Vti))/std(Vti);
    if mean(autocorr(Vti, maxlag)) >= meanvalue
        rankindx(vi) = 1;
    end
end

end


function corr = autocorr(x, maxlag)
if maxlag > length(x), maxlag = length(x); end

maxlag = min(maxlag, length(x));

funcNor = @(x) x - mean(x);
funcCov = @(x, lag) real(xcorr(funcNor(x),lag))/length(x);

cov = funcCov(x, maxlag);
corr  = cov /var(x);
corr= corr(maxlag+1:end);

end
