function learnFFTModel(filelist,saveFilename,parameter)
% learnHashprintModel(filelist,saveFilename,parameter)
% 
%   Learns the hashprint model based on a set of files, and writes
%   the model to the specified .mat file.
%
%   filelist is a text file specifying the audio files to process.
%   saveFilename is the name of the .mat file to save the model to.
%   parameter specifies arguments for the learning
%      parameter.m specifies the number of context frames used in 
%         the time-delay embedding
%      parameter.tao specifies the gap (in frames) between consecutive 
%         frames in the time-delay embedding.
%      parameter.hop specifies the hop size (in frames) between consecutive
%         time delay embedded features
%      parameter.numFeatures specifies the number of bits in the fingerprint.
%      parameter.deltaDelay is the delay (in hops) used in the 
%         delta feature computation.
%      parameter.precomputeCQT is 1 or 0, specifying if the CQT has been
%         precomputed.  
%      parameter.precomputeCQTdir specifies the directory containing the 
%         precomputed CQT .mat files.
%
% 2016-07-08 TJ Tsai ttsai@g.hmc.edu
if nargin<3
    parameter=[];
end
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
    parameter.numFeatures=64;
end
if isfield(parameter,'deltaDelay')==0
    parameter.deltaDelay=16;
end
if isfield(parameter,'precomputeCQT')==0
    parameter.precomputeCQT = 0;
end

disp(['-- Number of features: ', num2str(parameter.numFeatures)]);
%% Compute accumulated covariance matrix
fid = fopen(filelist);
curFileList = '';
fileIndex = 1;
curfile = fgetl(fid);
while ischar(curfile)
    curFileList{fileIndex} = curfile;
    curfile = fgetl(fid);
    fileIndex = fileIndex + 1;
end

agg = [];

%% step 1 - 4
for index = 1 : length(curFileList)
    curfile = curFileList{index};
    disp(['Generating data on #',num2str(index),': ',curfile]);
    Q = computeQSpec(curfile, parameter);
    Q = Q.c;
    sixSecLen = 1451;
    % partition into 6-sec chunks with a hop of 3-sec
    curr_agg = [];
    for col = 1 : floor(sixSecLen / 6): size(Q, 2) - sixSecLen + 1
        curr = Q(:, col : col + sixSecLen - 1);
        curr = computeFFTRep(curr, {}, parameter);
        curr_agg = cat(3, curr_agg, curr);
    end
    agg = cat(3, agg, curr_agg);
end

size(agg)

%% step 5: calculate variance for each pixel and select top N values
disp(['Computing variance on the aggregated matrix ... ']);
tic;

% cut agg to preserve only the top left corner and throw away the first column
agg = agg(2 : floor(size(agg, 1) / 2), 1 : floor(size(agg, 2) / 2), :);
var_agg = var(agg, 0, 3);
[~, I] = sort(var_agg(:), 'descend');
I_top = I(1 : (parameter.numFeatures / 2));
toc


%% fetching values for analysis
agg = reshape(agg, size(agg, 1) * size(agg, 2), 1, []);
agg_top = agg(I_top, 1, :);

%% save to file
disp(['Saving FFT models to file']);
save(saveFilename,'filelist','parameter', 'agg_top', 'var_agg', 'I_top');
