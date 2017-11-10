function [DB1, DB2] = genCQTdb(audio1, audio2, fs1, fs2, alignment)
%% argin:
%   audio1 is the first audio
%   audio2 is the second audio
%   alignment is the DTW alignment path, an array of tuples

fps = 1; % change this: num frames per second in the audio
nextstart1 = 1;
DB1 = {};
DB2 = {};

count = 0;
for nframe = 1 : size(alignment, 1)
    start1 = alignment(nframe, 1);
    if start1 < nextstart1
        continue;
    end
    start2 = alignment(nframe, 2);
    if (start1 + fps <= size(audio1, 2)) && start2 + fps <= size(audio2, 2)
        % compute cqt for the one second chunks
        y1 = audio1(start1 : start1 + fps);
        Q1 = computeQSpec(y1, fs1);
        y2 = audio(start2 : start2 + fps);
        Q2 = computeQSpec(y2, fs2);
        count = count + 1;
        DB1{count} = Q1.c;
        DB2{count} = Q2.c;
        nextstart1 = start1 + fps + 1;
    end
end
        
end