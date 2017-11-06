function runQueries_CNNdb(dbfile, queryRepFile, outdir)
% function runQueries(queriesFilelist,dbfile,outdir,qparam)
%
%   Runs a set of queries on a given database, and then dumps the
%   hypothesis to file.
%
%   dbfile is a .mat file containing the fingerprint database.
%   queryRepFile is a .mat file containing the hashprints representation 
%       of all queries.
%   outdir is the directory to dump hypothesis files
%

db = load(dbfile); % contains fingerprints, parameter, model, hopsize
fingerprints = struct2cell(db.DB).';
hopsize = db.hopsize;
queryDB = load(queryRepFile);
queries = struct2cell(queryDB.DB).';

tic;
for index = 1 : length(queries)

    % get hashprint of the current query 
    fpseq = queries{index}; 
    
    % get match scores
    R = fastMatchFpSeq(fpseq,fingerprints);
    %R = matchFingerprintSequence(fpseq,fingerprints);
    %disp('Done matching sequence\n');
    R(:,3) = R(:,3) * hopsize; % offsets in sec instead of hops
    
    % write to file
    outfile = strcat(outdir,'/',name,'.hyp');
    dlmwrite(outfile,R,'\t');
end
toc
fclose(fid);