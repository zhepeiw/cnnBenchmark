function [fingerprints] = getRepresentations(modelFile, computeFcn, flist)
% note that flist is different from filelist, which is loaded by modelFile
model = load(modelFile); % loads parameter and weight variables
parameter = model.parameter;

if nargin < 3
    flist = model.filelist;
end

fingerprints = {};
fid = fopen(flist);
count = 1;
curfile = fgetl(fid);

%% hashprints for original file
while ischar(curfile)
    tic;
    disp(['==> Computing fingerprints on file ',num2str(count),': ',curfile]);
    Q = computeQSpec(curfile,parameter); 
    % compute hashprints on original studio track
    fpseq = computeFcn(Q,model,parameter);
    fingerprints{count} = fpseq;
    
    % compare bit match
    count = count + 1;
    curfile = fgetl(fid);
    toc
end
fclose(fid);
end
