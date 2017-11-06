function F = computeFFTRep(Q, model, parameter)
% 
%   Input:
%	Q is a CQT struct
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

if nargin < 3
    parameter=[];
end

if isfield(Q,'c')~=0
    Q = Q.c;
end

%% step 2: preprocessing
prepQ = preprocessQspec_FFT(Q, parameter);

%% step 3: 2D FFT
F = fft2(prepQ);

if isfield(model,'I_top') ~= 0
	%% step 4: throw away the first column and keep only the top-left corner
	F = F(2 : floor(size(F, 1) / 2), 1 : floor(size(F, 2) / 2));
	%% step 5: take the top N/2 pixels with greatest variance
    F = F(model.I_top);
    %% step 6: stack real and imaginary part
    F = [real(F); imag(F)];
    F = F > 0;
end
