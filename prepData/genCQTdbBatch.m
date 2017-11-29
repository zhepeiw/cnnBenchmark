function genCQTdbBatch( reflist, querylist, alignlist, outdir )

%   Detailed explanation goes here
%   argin:
%       reflist is a .list file containing path to the ref audio files
%       querylist is a .list file containing path to the query audio files
%       alignlist is a .list file containing path to the alignment csv
%       files
%       outdir is the output directory to store the CQT matrices
%       
%%
if nargin < 4
    outdir = './';
end

%% read ref and query list
fid = fopen(reflist);
refFileList = '';
refFileIndex = 1;

curfile = fgetl(fid);
while ischar(curfile)
    refFileList{refFileIndex} = curfile;
    curfile = fgetl(fid);
    refFileIndex = refFileIndex + 1;
end
fclose(fid);

fid = fopen(querylist);
qFileList = '';
qFileIndex = 1;

curfile = fgetl(fid);
while ischar(curfile)
    qFileList{qFileIndex} = curfile;
    curfile = fgetl(fid);
    qFileIndex = qFileIndex + 1;
end
fclose(fid);

fid = fopen(alignlist);
alignments = '';
alignIndex = 1;

curfile = fgetl(fid);
while ischar(curfile)
    alignments{alignIndex} = curfile;
    curfile = fgetl(fid);
    alignIndex = alignIndex + 1;
end
fclose(fid);

%% generate database

for index = 1 : length(refFileList)
    [orig, fs_orig] = audioread(refFileList{index});
    [q1, fs1] = audioread(qFileList{2 * index - 1});
    [q2, fs2] = audioread(qFileList{2 * index});
    align1 = csvread(alignments{2 * index - 1}, 1, 0);
    align2 = csvread(alignments{2 * index}, 1, 0);
    [fname1, ~] = splitPath(qFileList{2 * index - 1});
    [fname2, ~] = splitPath(qFileList{2 * index});
    
    genCQTdb(q1, orig, fs1, fs_orig,...
        align1, strcat(outdir, fname1, '.mat'));
    genCQTdb(q2, orig, fs2, fs_orig,...
        align2, strcat(outdir, fname2, '.mat'));
    
end

end
