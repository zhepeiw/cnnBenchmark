function genCQTdb(audio1, audio2, fs1, fs2, alignment, savename)
%% argin:
%   audio1 is the first audio
%   audio2 is the second audio
%   alignment is the DTW alignment path, an array of tuples

addpath('./cqt/');
hop_chromo = 512;
DB1 = {};
DB2 = {};
fps1 = ceil(fs1/ hop_chromo);
fps2 = ceil(fs2/ hop_chromo);
count = 0;
for nframe = 1 : fps1 : size(alignment, 1)
    start1 = alignment(nframe, 1) + 1; % offset with python index
    start2 = alignment(nframe, 2) + 1;
    if (start1 + fps1 <= length(audio1)) && (start2 + fps2 <= length(audio2))
        % compute cqt for the one second chunks
        y1 = audio1(start1  : start1 + fs1 - 1);
        Q1 = computeQSpec(y1, fs1);
        y2 = audio2(start2 : start2 + fs2 - 1);
        Q2 = computeQSpec(y2, fs2);
        count = count + 1;
        DB1{count} = Q1.c;
        DB2{count} = Q2.c;
    end
end
db_query = reshape(cell2mat(DB1), size(DB1{1}, 1), size(DB1{1}, 2), []);
db_ref = reshape(cell2mat(DB2), size(DB2{1}, 1), size(DB2{1}, 2), []);

save(savename, 'db_query', 'db_ref');

end