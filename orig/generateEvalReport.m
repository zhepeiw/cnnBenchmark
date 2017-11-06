function generateEvalReport( nameList, pctList, corrList, oneList, xbMat, ...
    outPath, saveMatPath )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
disp(['==> Generating report for ', outPath]);
fid = fopen(outPath, 'w');

%% correlation report
for row = 1 : size(corrList, 1)
        fprintf(fid, '-> Bit %d : fraction of bits remained %f \n', ...
            row, corrList(row));
end
fprintf(fid, '%s \n', '========================================');

%% bit percentage report
for row = 1 : size(oneList, 1)
        fprintf(fid, '-> Bit %d : fraction of ones %f \n', ...
            row, oneList(row));
end
fprintf(fid, '%s \n', '========================================');

%% comparison report
for index = 2 : length(nameList)
    fprintf(fid, '--%s : %f \n', nameList{index}, pctList(index));    
end

%% saving data
fprintf(fid, '-> Saving data into %s \n', saveMatPath);
save(saveMatPath, 'pctList', 'corrList', 'oneList', 'xbMat');
fclose(fid);
