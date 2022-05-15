function [sourceInterp] = align_map(Config)
% ALIGN_MAP
% Required:
%   Config.map
% or
%   Config.evaluation
%
%   Config.mriPrepro
%   Config.mriTarget
%   Config.sourcemodel.dim
%   Config.sourcemodel.pos
%   Config.sourcemodel.unit
%   Config.sourcemodel.inside
%
% Optional:
%   Config.output
%   Config.plot
%   Config.visualize
%   Config.allowExistingFolder
%
%   Config.mriPreproVarName
%   Config.mriTargetVarName
%   Config.sourcemodelVarName

%% Constants
PLOT = false;
VISUALIZE = true;
ALLOW_EXISTING_FOLDER = false;

SOURCEMODEL_VAR_NAME = 'sourcemodel';

%% Options
if ~isfield(Config, 'plot')
    Config.plot = PLOT;
end
plot = Config.plot;

if ~isfield(Config, 'visualize')
    Config.visualzie = VISUALIZE;
end
visualize = Config.visualize;

if ~isfield(Config, 'allowExistingFolder')
    Config.allowExistingFolder = ALLOW_EXISTING_FOLDER;
end
allowExistingFolder = Config.allowExistingFolder;

if isfield(Config, 'output')
    Config.output = convertStringsToChars(Config.output);
end

%% Config
check_required_field(Config, 'mriTarget');
check_required_field(Config, 'mriPrepro');
check_required_field(Config, 'sourcemodel');

if isfield(Config, 'output')
    [Config.output, imgPath] = create_output_folder(Config.output, allowExistingFolder);
end

if isfield(Config, 'map')
    eval = false;
    map = Config.map;
elseif isfield(Config, 'evaluation')
    eval = true;
    evaluation = convertStringsToChars(Config.evaluation);
    if ischar(evaluation)
        evaluation = load_var_from_mat('evaluation', evaluation);
    else
        evaluation = Config.evaluation;
    end
else
    error("Please, include 'Config.map' or 'Config.evaluation'.")
end

sourcemodel = convertStringsToChars(Config.sourcemodel);
if ischar(sourcemodel)
    if isfield(Config, 'sourcemodelVarName')
        sourcemodel = load_var_from_mat(Config.sourcemodelVarName, sourcemodel);
    else
        sourcemodel = load_var_from_mat(SOURCEMODEL_VAR_NAME, sourcemodel);
    end    
else
    sourcemodel = Config.sourcemodel;
end
check_required_field(sourcemodel, 'dim');
check_required_field(sourcemodel, 'pos');
check_required_field(sourcemodel, 'unit');
check_required_field(sourcemodel, 'inside');

if ~isfield(Config, 'mriTargetVarName')
    Config.mriTargetVarName = 'mriCommon';
end
mriTarget = load_mri_anytype(Config.mriTarget, Config.mriTargetVarName);

if ~isfield(Config, 'mriPreproVarName')
    Config.mriPreproVarName = 'mriPrepro';
end
mriPrepro = load_mri_anytype(Config.mriPrepro, Config.mriPreproVarName);

%% Align prepro MRI to common MRI
cfg = struct;
cfg.method = 'spm';
mriNorm = ft_volumerealign(cfg, mriPrepro, mriTarget);

%% Prepare plot struct
nDipoles = length(sourcemodel.inside);
source = struct;
source.dim = sourcemodel.dim;
source.pos = sourcemodel.pos;
source.unit = sourcemodel.unit;

%% Transform pos
pos = [source.pos ones(nDipoles, 1)]';
pos = (mriPrepro.transform^-1 * pos);
pos = (mriNorm.transform * pos);
source.pos = pos(1:3,:)';

%% Add maps
if eval
    mapNames = {'ed1', 'ed2'};
    maps = evaluation.eloreta.snr10;
    axisNames = {'x', 'y', 'z'};
else
    mapNames = {'map'};
    maps = struct;
    maps.map = make_column(map);
    axisNames = {''};
end
nMaps = length(mapNames);
nAxis = length(axisNames);
parameters = cell(1, nMaps * nAxis);
for m = 1:nMaps
    for a = 1:nAxis
        param = [mapNames{m} axisNames{a}];
        source.(param)                     = zeros(nDipoles, 1);
        source.(param)(sourcemodel.inside) = maps.(mapNames{m})(:,a);
        parameters{((m-1)*nAxis) + a} = param;
    end
end
        

%% Interpolate map to target MRI
cfg = struct;
cfg.parameter = parameters;
cfg.downsample = 1; % defualt
cfg.interpmethod = 'linear'; % default
sourceInterp = ft_sourceinterpolate(cfg, source, mriTarget);

if isfield(Config, 'output')
    save([Config.output '\source_interp'], 'sourceInterp');
end

%% Prepare plot config
if ~plot
    return
end

sourceInside = source;
sourceInside.inside = sourcemodel.inside;

cfg = struct;
cfg.crosshair = 'no'; % default
cfg.location = 'center';
cfg.mri = mriTarget;
cfg.visualize = visualize;
for m = 1:nMaps
    for a = 1:nAxis
        param = parameters{((m-1)*nAxis) + a};
        cfg.parameter = param;
        
        %% Plot interpolated
        cfg.name = [param '_interp'];
        if exist('imgPath', 'var')
            cfg.save = [imgPath '\' cfg.name];
        end
        plot_source(cfg, sourceInterp);

        %% Plot
        cfg.name = param;
        if exist('imgPath', 'var')
            cfg.save = [imgPath '\' cfg.name];
        end
        plot_source(cfg, sourceInside);
    end
end
end
