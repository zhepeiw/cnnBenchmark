function A = getTDE(spec,parameter)
% A = getTDE(spec,parameter)
%
%   Create a data matrix A containing time-delay embeddings for the 
%   frames in a given spectrogram.
%
%   spec is a matrix specifying a spectrogram, where the rows correspond
%   to different frequency bands and the columns correspond to different
%   time frames.
% 
%   parameter specifies the arguments for the time delay embedding
%     parameter.m specifies the total number of context frames in 
%       the time-delay embedding.
%     parameter.tao specifies the delay (in frames) between consecutive
%       context frames in the time-delay embedding.
%     parameter.hop specifies the hop size (in frames) between consecutive
%       TDE features
%
%   A is a data matrix whose columns correspond to different frames, and
%   whose rows correspond to the time-delay embedded features.
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

numFrames = size(spec,2);
numPitches = size(spec,1);
tdespan = parameter.tao*(parameter.m-1)+1;
endIdx = numFrames - tdespan + 1;
offsets = 1:parameter.hop:endIdx;
A = zeros(length(offsets),numPitches*parameter.m);
for i=1:parameter.m,
    frameIdxs = offsets + (i-1)*parameter.tao;
    A(:,(1+(i-1)*numPitches):(i*numPitches)) = spec(:,frameIdxs).';
end
A = A.';

