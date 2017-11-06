% Example input:
% outdir = './out/';
% PREFIX = 'taylorswift_query';
% queriesToRefFilelist = './audio/taylorswift_querytoref.list';
function MRR = calculateMRR(queriesToRefFilelist, PREFIX, outdir)
% This function calculates the MRR value. The input parameters are
%       queriesToRefFilelist - indicates the expected matched between
%                              queries and references
%       PREFIX - indicates the prefix of the hypothesis files before number
%       outdir - indicates the directory of hypothesis file
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    fid = fopen(queriesToRefFilelist);
    count = 0;

    sum_RR = 0;
    while true
        line = fgetl(fid);
        if(~ischar(line)) 
            break
        end
        data = sscanf(line, '%g %g', 2);
        query_id = data(1);
        targetRef_id = data(2);
        count = count + 1;
        hypothesis_file = strcat(outdir, PREFIX, num2str(count), '.hyp');
        sum_RR = sum_RR + 1.0 / findRank(hypothesis_file, targetRef_id);
    end 
    MRR = sum_RR / count;
end

function rank = findRank(hypothesis_file, expected)
    fid = fopen(hypothesis_file);
    currentLineNo = 0;
    while true
       line = fgetl(fid);
       if(~ischar(line))
           break
       end
       currentLineNo = currentLineNo + 1;
       currentPrediction = sscanf(line, '%g',1);
       if (currentPrediction == expected)
           rank = currentLineNo;
           break
       end
    end
end
