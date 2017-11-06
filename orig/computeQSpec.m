function Q = computeQSpec(file,param)
% Q = computeQSpec(file,param)
%
%   Computes constant Q transform on the specified wav file
%
%   file is the full path of the wav file
%   param specifies parameters for the CQT
%      param.targetsr is the target sample rate (before computing CQT)
%      param.B is the number of bins per octave
%      param.fmin is the min freq to analyze
%      param.fmax is the max freq to analyze
%      param.gamma specifies bandwidth factor (0 for constant Q)
%      param.precomputeCQT specifies whether to load a precomputed CQT
%      param.precomputeCQTdir specifies where to find precomputed CQT files
%
%   2016-07-08 TJ Tsai ttsai@g.hmc.edu

if nargin < 2
    param = [];
end
if isfield(param,'targetsr') == 0
    param.targetsr = 22050;
end
if isfield(param,'B')==0
    param.B = 24;
end
if isfield(param,'fmin')==0
    param.fmin = 130.81;
end
if isfield(param,'fmax')==0
    param.fmax = 4186.01;
end
if isfield(param,'gamma')==0
    param.gamma = 0;
end
if isfield(param,'precomputeCQT')==0
    param.precomputeCQT = 0;
end


if param.precomputeCQT
    [pathstr,name,ext] = fileparts(file);
    cqt_file = strcat(param.precomputeCQTdir,'/',name,'.mat');
    load(cqt_file); % loads Q (struct)
else
    [y,fs] = audioread(file);
    y = sum(y,2); % mono
    y = resample(y,param.targetsr,fs);
    Q = cqt(y,param.B,param.targetsr, ...
        param.fmin,param.fmax,'gamma',param.gamma);
end

