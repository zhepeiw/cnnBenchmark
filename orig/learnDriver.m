%% flag setup
REPFLAG = 2;
modelName = 'hp_64b';
reportName = 'hp_64b';
artist = 'taylorswift';
reflist = strcat('./audio/', artist, '_ref.list');
querylist = strcat('./audio/', artist, '_query.list');
outdir = strcat('/pylon2/ci560sp/haunter/results/', artist, '_out/');

addpath('./cqt/');
%% Parallel computing setup
curPool = gcp('nocreate'); 
if (isempty(curPool))
    myCluster = parcluster('local');
    numWorkers = myCluster.NumWorkers;
    % create a parallel pool with the number of workers in the cluster
    pool = parpool(numWorkers);
end

%% precompute CQT on reflist
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
