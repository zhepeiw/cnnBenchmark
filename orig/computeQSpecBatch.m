function computeQSpecBatch(filelist,featDir,param)
%  computeQSpecBatch(filelist,featDir,param)
%
%    Computes constant Q transform on the specified list of files and 
%    saves the results to an output directory.
%
%    filelist is a text file containing a list of wav files, one per line.
%       The files should have unique basenames.
%    featDir specifies where to save the CQT data
%    param specifies parameters for computing CQT
%       param.targetsr is the desired sample rate before CQT computation
%       param.B is the number of bins per octave
%       param.fmin is the lowest frequency to be analyzed (Hz)
%       param.fmax is the highest frequency to be analyzed (Hz)
%       param.gamma specifies factor in filter bandwidth (0 => CQT)
%
%  2016-07-08 TJ Tsai ttsai@g.hmc.edu

if nargin < 3
    param = []; % will use default settings
end


fid = fopen(filelist);
curFileList = '';
fileIndex = 1;

curfile = fgetl(fid);
while ischar(curfile)
    curFileList{fileIndex} = curfile;
    curfile = fgetl(fid);
    fileIndex = fileIndex + 1;
end

parfor index = 1:length(curFileList)
    curfile = curFileList{index};
    [pathstr,name,ext] = fileparts(curfile);
    disp(['Computing CQT on ',name]);
    savefile = strcat(featDir,'/',name,'.mat');
    if exist(savefile,'file') ~= 2
        Q = computeQSpec(curfile,param);
        parSave(savefile, Q);
    end
end

fclose(fid);

end

function parSave(fname, Q)
save(fname, 'Q');
end

