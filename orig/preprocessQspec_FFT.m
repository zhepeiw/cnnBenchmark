function B = preprocessQspec_FFT(Q, param)
% B = preprocessQspec(Q)
%
%  B is a matrix containing the pre-processed log CQT coefficients.
%  With default parameter settings, B contains 121 log energy
%  coefficients approximately every 12.4 ms.
%
% 2016-07-08 TJ Tsai ttsai@g.hmc.edu

if nargin < 2
	param = [];
end

if isfield(param, 'downsample')==0
	param.downsample = 3;
end

downsample = param.downsample; % average over this many frames (3 --> approx 12.4ms per hop)
groupSize = 1; % group consecutive frames into one chunk
numPitches = size(Q,1);
numChunks = floor(size(Q,2)/(downsample*groupSize));
A = abs(Q(:,1:(numChunks*downsample*groupSize)));

% first average over downsample frames
A = reshape(A,numPitches,downsample,numChunks*groupSize);
A = mean(A,2);
A = reshape(A,numPitches,numChunks*groupSize);

% now combine consecutive frames into groups
A = reshape(A,numPitches*groupSize,numChunks);
B = log(1+1000000*A);

