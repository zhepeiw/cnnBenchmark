function F = computeHashprints(Q,model,parameter)
% F = computeHashprints(spec,filters,parameter)
% 
%   Computes a sequence of hashprints on the given preprocessed CQT coefficients.
%   
%   spec is a matrix specifying the preprocessed CQT coefficients, where the 
%   rows correspond to different frequency bands, and the columns 
%   correspond to different frames.
%
%   filters is a matrix whose columns specify the spectrotemporal filters
%   to apply at each frame.  These filters assume a time-delay embedding
%   as specified in parameter.
%
%   parameter is a struct specifying various arguments:
%     parameter.m is the number of context frames to use in the time-delay
%       embedding.
%     parameter.tao is the separation (in frames) between consecutive frames
%       in the time-delay embedding.
%     parameter.hop is the hop size (in frames) between consecutive
%       time delay embedded features.
%     parameter.numFeatures specifies the number of spectrotemporal features.
%     parameter.deltaDelay specifies the delay (in hops) to use for the 
%       delta feature computation.
%
%   F is a matrix of logical values containing the computed fingerprint
%   bits.  The rows correspond to different bits in the fingerprint, and
%   the columns correspond to different frames.
%
%  2016-07-08 TJ Tsai ttsai@g.hmc.edu
if nargin < 3
    parameter=[];
end

filters = model.eigvecs;

if isfield(parameter,'m')==0
    parameter.m=20;
end
if isfield(parameter,'tao')==0
    parameter.tao=1;
end
if isfield(parameter,'hop')==0
    parameter.hop=5;
end
if isfield(parameter,'numFeatures')==0
    parameter.numFeatures=size(filters,2);
end
if isfield(parameter,'deltaDelay')==0
    parameter.deltaDelay=16;
end

spec = preprocessQspec(Q);
A = getTDE(spec,parameter);
features = (A.'*filters(:,1:parameter.numFeatures)).';
deltas = features(:,1:(size(features,2)-parameter.deltaDelay)) - features(:,(1+parameter.deltaDelay):end);
F = deltas > 0;
