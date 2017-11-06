function [C,N] = getTDECov(filename,parameter)
% [C,N] = getTDECov(filename,parameter)
%    Compute the Q-transform time-delay embedding covariance matrix 
%    for a single wav file.  A constant Q transform is computed on
%    the specified file, and each frame is represented with a time-
%    delay embedding with m frames each separated by tao frames.
%
% Input:
%    filename
%    parameter.m = 20;
%    parameter.tao = 1;
%    parameter.hop = 5;
%    parameter.precomputeCQT = 0; 
%    parameter.precomputeCQTdir
%
% Output:
%    C is the covariance matrix.
%    N is the number of samples used to estimate C.
%
% 2016-07-08 TJ Tsai ttsai@g.hmc.edu

if nargin<2
    parameter=[];
end
if isfield(parameter,'m')==0
    parameter.m = 20;
end
if isfield(parameter,'tao')==0
    parameter.tao=1;
end
if isfield(parameter,'hop')==0
    parameter.hop=5;
end
if isfield(parameter,'precomputeCQT')==0
    parameter.precomputeCQT = 0;
end

Q = computeQSpec(filename,parameter); % struct
logQ = preprocessQspec(Q); % downsampled, log CQT coefficients
A = getTDE(logQ,parameter);
C = cov(A.');
N = size(A,2);
