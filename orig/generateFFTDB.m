function generateFFTDB(modelFile, computeFcn, flist, saveFilename)
% generateDB(modelFile,saveFilename)
%
%   generateDB computes hashprints on a set of studio tracks and saves 
%   the fingerprint database to the specified file.
%
%    modelFile: file specifying the hashprint model.  This is the file
%      produced by learnHashprintModel.  Note that this model file also
%      specifies the list of studio tracks to process.
%    saveFilename: the name of the file to save the fingerprint database
%
%   Note that, in addition to computing hashprints on the original studio
%   recordings, generateDB also computes hashprints on pitch-shifted
%   versions.
%
% 2016-07-08 TJ Tsai ttsai@g.hmc.edu

model = load(modelFile);
parameter = model.parameter;

fingerprints = {};
idx2file = {};

fid = fopen(flist);
curFileList = '';
fileIndex = 1;
curfile = fgetl(fid);
tmpfile = curfile;
while ischar(curfile)
    curFileList{fileIndex} = curfile;
    curfile = fgetl(fid);
    fileIndex = fileIndex + 1;
end

tic;
parfor index = 1 : length(curFileList)
    curfile = curFileList{index};
    disp(['Computing fingerprints on file ',num2str(index),': ',curfile]);
    Q = computeQSpec(curfile,parameter);
    Q = Q.c;
    % compute hashprints on original studio track
    sixSecLen = 1451;
    % partition into 6-sec chunks with a hop of 3-sec
    curr_agg = [];
    for col = 1 : parameter.hop : size(Q, 2) - sixSecLen + 1
        curr = Q(:, col : col + sixSecLen - 1);
        F = computeFcn(curr, model, parameter);
        curr_agg = cat(2, curr_agg, F);
    end
    cat3 = cat(3, curr_agg, curr_agg);
    fingerprints{index} = cat3(:, :, 1);
    idx2file{index} = curfile;
end
toc
fclose(fid);

% compute hop size -- hack!
Q = computeQSpec(tmpfile,parameter);
hopsize = Q.xlen/(22050*size(Q.c,2))*3*parameter.hop;
    
disp(['Saving fingerprint database to file']);
save(saveFilename,'flist','parameter','model',...
    'fingerprints','idx2file','hopsize', '-v7.3');
