%% Innit
clear variables
close all
cfg = struct;

%% Output
% TODO make simple path option
% Results will be saved in 'resultsPath\analysisName\dataName\runName'
cfg.resultsPath = 'C:\Users\matou\Documents\MATLAB\BP_MIDA\data\out';
cfg.analysisName = 'pipeline_test';
cfg.dataName = 'ANDROVICOVA_RENATA';
cfg.runName = '01';

% Note that setting [path.output] in any of the submodules will have no
% effect. Output paths for submodules are generated by the pipeline.

%% Segmentation
dataPath = 'C:\Users\matou\Documents\MATLAB\BP_MIDA\data';
mriDataPath = [dataPath '\data\MR\ANDROVICOVA_RENATA_8753138768\HEAD_VP03_GTEN_20181204_120528_089000\T1_SAG_MPR_3D_1MM_ISO_P2_0002'];
mriPathIMA = [mriDataPath '\ANDROVICOVA_RENATA.MR.HEAD_VP03_GTEN.0002.0027.2018.12.12.08.59.13.218838.497729096.IMA'];
mriPathNII = [mriDataPath '\T1_SAG_MPR_3D_1MM_ISO_P2_0002_t1_sag_mpr_3D_1mm_ISO_p2_20181204120528_2.nii,1'];

% TODO add optional array of wanted methods:
%cfg.segmentation.method = ['fieldtrip', 'mrtim', brainstorm];

% Uncomment one or more segmentation methods below:
%% Segmentation - FieldTrip
% See 'segmentation\fieldtrip\run_segmentation_fieldtrip.m' for all options
cfg.segmentation.fieldtrip.path.fieldtrip = [matlabroot '\toolbox\fieldtrip'];
cfg.segmentation.fieldtrip.mri = mriPathIMA; % TODO add support for var instead of path

%% Segmentation - MR-TIM
% See 'segmentation\mrtim\run_segmentation_mrtim.m' for all options
cfg.segmentation.mrtim.path.spm = [matlabroot '\toolbox\spm12'];
cfg.segmentation.mrtim.path.mrtim = [matlabroot '\toolbox\spm12\toolbox\MRTIM'];
cfg.segmentation.mrtim.mri = mriPathNII;

%% Segmentation - Brainstorm (TODO)

%% Segmentation - already segmented MRI (TODO)
%cfg.segmentation.mriSegmented.path = ;
% or
%cfg.segmentation.mriSegmented.mri = ;

%% Model
% TODO add optional array of wanted methods:
%cfg.model.method = ['fieldtrip', 'brainstorm'];

% Uncomment one or more modeling methods below:
%% Model - FieldTrip
% See 'model\fieldtrip\run_model_fieldtrip.m' for all options
cfg.model.fieldtrip.path.fieldtrip = [matlabroot '\toolbox\fieldtrip'];

% (A) STANDALONE MODELING
% Set segmented MRI path:
% (i) path to a MRI segmented by FieldTrip (5 layers)
cfg.model.fieldtrip.mriSegmented.path = [dataPath '\out\pipeline_test\ANDROVICOVA_RENATA\03\segmentation\fieldtrip\mri_segmented.mat'];
cfg.model.fieldtrip.mriSegmented.method = 'fieldtrip';
cfg.model.fieldtrip.mriSegmented.nLayers = 5;

% (ii) path to a MRI segmented by MR-TIM (6 or 12 layers)
%cfg.model.fieldtrip.mriSegmented.path = [dataPath '\out\pipeline_test\ANDROVICOVA_RENATA\03\segmentation\mrtim\mri_segmented.mat'];
%cfg.model.fieldtrip.mriSegmented.method = 'mrtim';
%cfg.model.fieldtrip.mriSegmented.nLayers = 12;

% (B) PIPELINE MODELING
% Specify a previous segmentation submodule to follow up on:
%cfg.model.fieldtrip.submodule = 'fieldtrip';
% Choose from ['fieldtrip', 'mrtim', 'brainstorm'].

%% Model - Brainstorm (TODO)

%% Miscellaneous
% If set, it will override all submodule 'visualize' options.
cfg.miscellaneous.visualize = true;

% Useful for manual run of parts of the pipeline:
%Config = cfg; clear cfg;

%% Run
forward_problem_pipeline(cfg);
