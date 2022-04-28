%% Paths & Names - Set manually
Path.output.root = 'S:\BP_MIDA\analysis';
Path.output.nudz = [Path.output '\NUDZ'];

methods =       {'fieldtrip',                 'fieldtrip',                 'mrtim'};
layers =        [ 3,                           5,                           12];
suffixes =      {'anatomy_prepro',            'anatomy_prepro',            ''};

segFileName = 'mri_segmented.mat';
sourcemodelFileName = 'sourcemodel.mat';
sourcemodelVarName = 'sourcemodel';

%% Import source code & Init toolboxes
addpath_source

%% Get paths to segmentations
methods = convertStringsToChars(methods);
suffixes = convertStringsToChars(suffixes);
segFileName = convertStringsToChars(segFileName);

nSegmentations = length(methods);
segmentations = cell(1, nSegmentations);
for m = 1:nSegmentations
    suffix = '';
    if ~isempty(suffixes{m})
        suffix = ['_' suffixes{m}];
    end
    segmentations{m} = [methods{m} num2str(layers(m)) suffix];
end

subjects = dir([Path.output.nudz '\*_*_*']);
nSubjects = length(subjects);
for s = 1:nSubjects
    for m = 1:nSegmentations
        Path.(subjects(s).name).segmentation.(segmentations{m}) =...
            [subjects(s).folder '\' subjects(s).name '\segmentation\' segmentations{m} '\' segFileName];
    end
end

%% Prepare models
cfgPipeline = struct;
cfgPipeline.resultsPath = Path.output.root;
cfgPipeline.dataName = 'NUDZ';
cfgPipeline.visualize = false;
cfgPipeline.dialog = false;
cfgPipeline.model = struct;
cfgPipeline.model.fieldtrip = struct;

sourcemodelCheck = NaN(nSubjects, 1);
pairs = nchoosek(1:nSegmentations, 2);
nPairs = length(pairs);
for s = 1:nSubjects
    Sourcemodel = struct;
    for m = 1:nSegmentations
        %% Prepare model
        cfgPipeline.subjectName = subjects(s).name;
        cfgPipeline.model.fieldtrip.mriSegmented.path =...
            Path.(subjects(s).name).segmentation.(segmentations{m});
        cfgPipeline.model.fieldtrip.mriSegmented.method = methods{m};
        cfgPipeline.model.fieldtrip.mriSegmented.nLayers = layers(m);
        forward_problem_pipeline(cfgPipeline);
        
        %% Load sourcemodel for check
        sourcemodelPath = [subjects(s).folder '\' subjects(s).name '\model\' segmentations{m} '\' sourcemodelFileName];
        Data = load(sourcemodelPath, sourcemodelVarName);
        sourcemodel = Data.(sourcemodelVarName);
        Sourcemodel.(segmentations{m}) = rmfield(sourcemodel, 'cfg');
    end
    
    %% Check if all sourcemodels match
    for p = 1:nPairs
        sourcemodelA = Sourcemodel.(segmentations{pairs(p,1)});
        sourcemodelB = Sourcemodel.(segmentations{pairs(p,2)});
        if ~isequal(sourcemodelA, sourcemodelB)
            sourcemodelCheck(s) = 0;
        end
    end
    if sourcemodelCheck(s) ~= 0
        sourcemodelCheck(s) = 1;
    end
end
