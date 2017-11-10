function [ stack1, stack2 ] = genCQTdbBatch( reflist, querylist, alignments )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

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

%% generate database
stack1 = [];
stack2 = [];

for index = 1 : length(refFileList)
    [orig, fs_orig] = audioread(refFileList{index});
    [q1, fs1] = audioread(qFileList{2 * index - 1});
    [q2, fs2] = audioread(qFileList{2 * index});
    [db_orig1, db1] = genCQTdb(orig, q1, fs_orig, fs1, ...
        alignments{2 * index - 1});
    [db_orig2, db2] = genCQTdb(orig, q2, fs_orig, fs2, ...
        alignments{2 * index});
    % combine into two stacks
    stack1 = cat(1, stack1, cell2mat(db_orig1.'));
    stack1 = cat(1, stack1, cell2mat(db_orig2.'));
    stack2 = cat(1, stack2, cell2mat(db1.'));
    stack2 = cat(1, stack2, cell2mat(db2.'));
end

