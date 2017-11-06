addpath('./cqt/');
%% Parallel computing setup
curPool = gcp('nocreate'); 
if (isempty(curPool))
    myCluster = parcluster('local');
    numWorkers = myCluster.NumWorkers;
    % create a parallel pool with the number of workers in the cluster`
    pool = parpool(ceil(numWorkers * 0.75));
end

%% precompute CQT on reflist
reflist = strcat('./audio/', artist, '_ref.list');
querylist = strcat('./audio/', artist, '_query.list');
outdir = strcat(artist, '_out/');
mkdir(outdir)

param.precomputeCQT = 0;
param.precomputeCQTdir = outdir;
computeQSpecBatch(reflist,outdir, param);
computeQSpecBatch(querylist, outdir, param);

%% learn models and generate representations
param.m = -1;
modelFile = strcat(outdir, modelName, '.mat');
computeFcn = 0;

% switch for different representations
if LEARNFLAG
    switch REPFLAG
        case 1
            param.m = 20;
            param.numFeatures = 64;
    		prompt = 'Enter the number of features (default is 64): \n';
    		param.numFeatures = input(prompt);
            learnHashprintModel(reflist, modelFile, param);
            computeFcn = @computeHashprints;
        otherwise
            pass
    end

if TESTFLAG
    %% generate database: this step would be handled by python
    ref_db_file = strcat(outdir, modelName, 'ref_db.mat');
    query_db_file = strcat(outdir, modelName, 'qry_db.mat');
    runQueries_CNNdb(ref_db_file, query_db_file, outdir);   
    %% run MRR
    q2rList = strcat('./audio/', artist, '_querytoref.list');
    disp(['Calculating MRR for ', artist, ' test queries']);
    testMRR = calculateMRR(q2rList, strcat(artist, '_query'), outdir);
    disp(['Test MRR is ', num2str(testMRR)]);
end
