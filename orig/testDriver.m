%% flag setup
REPFLAG = 2;
modelName = 'hp_64b';
reportName = 'hp_64b';
artist = 'taylorswift';
reflist = strcat('./audio/', artist, '_ref.list');
querylist = strcat('./audio/', artist, '_query.list');
outdir = strcat(artist, '_out/');

addpath('./cqt/');
%% Parallel computing setup
curPool = gcp('nocreate'); 
if (isempty(curPool))
    myCluster = parcluster('local');
    numWorkers = myCluster.NumWorkers;
    % create a parallel pool with the number of workers in the cluster`
    pool = parpool(numWorkers);
end

modelFile = strcat(outdir, modelName, '.mat');

%% generate database: this step would be handled by python
ref_db_file = strcat(outdir, modelName, 'ref_db.mat');
query_db_file = strcat(outdir, modelName, 'qry_db.mat');
%% testing
runQueries_CNNdb(ref_db_file, query_db_file, outdir);   
%% run MRR
q2rList = strcat('./audio/', artist, '_querytoref.list');
disp(['Calculating MRR for ', artist, ' test queries']);
testMRR = calculateMRR(q2rList, strcat(artist, '_query'), outdir);
disp(['Test MRR is ', num2str(testMRR)]);
