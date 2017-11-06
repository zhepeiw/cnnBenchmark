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
outdir = strcat(artist, '_out/');
mkdir(outdir)

param.precomputeCQT = 0;
param.precomputeCQTdir = outdir;
computeQSpecBatch(reflist,outdir, param);

%% learn models and generate representations
param.m = -1;
modelFile = strcat(outdir, modelName, '.mat');
computeFcn = 0;
% switch for different representations
switch REPFLAG
    case 1
        param.m = 20;
        param.numFeatures = 64;
		prompt = 'Enter the number of features (default is 64): \n';
		param.numFeatures = input(prompt);
        learnHashprintModel(reflist, modelFile, param);
        computeFcn = @computeHashprints;

    case 2
        param.m = 20;
        param.numFeatures = 64;
        prompt = 'Enter the number of features (default is 64): \n';
        param.numFeatures = input(prompt);
        learnFFTModel(reflist, modelFile, param);
        computeFcn = @computeFFTRep;

    otherwise
        pass
end

if TESTFLAG
    %% generate database
    dbFile = strcat(outdir, modelName, '_db.mat');
    if REPFLAG == 2
        generateFFTDB(modelFile, computeFcn, reflist, dbFile);
    else
        generateDB(modelFile, computeFcn, reflist, dbFile);
    end
    disp(['Database saved at ', dbFile]);
    
    %% run test queries
    queryList = strcat('./audio/', artist, '_query.list');
    
    runQueries(queryList, dbFile, computeFcn, outdir);
    
    %% run MRR
    q2rList = strcat('./audio/', artist, '_querytoref.list');
    disp(['Calculating MRR for ', artist, ' test queries']);
    testMRR = calculateMRR(q2rList, strcat(artist, '_query'), outdir);
    disp(['Test MRR is ', num2str(testMRR)]);
end

if VALFLAG
    %% generate database
    dbFile = strcat(outdir, modelName, '_db.mat');
    generateDB(modelFile, computeFcn, reflist, dbFile);
    disp(['Database saved at ', dbFile]);
    
    %% run validation queries
    queryList = strcat('./audio/', artist, '_val.list');
    runQueries(queryList, dbFile, computeFcn, outdir);
    
    %% run MRR
    q2rList = strcat('./audio/', artist, '_valtoref.list');
    disp(['Calculating MRR for ', artist, ' validation queries']);
    valMRR = calculateMRR(q2rList, strcat(artist, '_val'), outdir);
    disp(['Validation MRR is ', num2str(valMRR)]);
end
