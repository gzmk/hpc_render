% Author: Gizem Kucukoglu
% April 2015

function render_bumpy_fits(gloss_level, fit_results)

%% Render bumpy spheres using the fit results 
% Gloss level: 0,10,20...,100 % gloss
% bump_level: 0.4 to 4.4 in increments of 0.4
% needs mat file of best fit parameter values as an 11x3 matrix
% rows: [1-matte, 2-10%, 3-20%, ..., 11- 100% gloss]
% cols: [rho_s rho_d alpha]

%scene33.hdr

load(fit_results)

row_no = (gloss_level/10)+1
var = normalised_params(row_no,:)
% Setup conditions file
fixed1 = var(1);
fixed2 = var(2);


ro_s = ['300:',num2str(var(1)),' 800:',num2str(var(1))];
ro_d = ['300:', num2str(var(2)), ' 800:', num2str(var(2))];
alphau = var(3); % alphau and alphav should always be the same value for isotropic brdf
light = ['300:', num2str(1), ' 800:',num2str(1)];
mycell = {ro_s, ro_d, alphau};

T = cell2table(mycell, 'VariableNames', {'ro_s' 'ro_d' 'alphau'});
writetable(T,'/scratch/gk925/hpc_render/render_scene4/bumpy_fitrender_Conditions.txt','Delimiter','\t')

% Set preferences
setpref('RenderToolbox3', 'workingFolder', '/scratch/gk925/hpc_render/render_scene4');

for bump = 0.4:0.4:4.4
    bump_level = strrep(num2str(bump), '.', '_');
    % use this scene and condition file. 
    parentSceneFile = ['bumpy',bump_level,'_5by5_correctCameraDist4.dae']
    conditionsFile = 'bumpy_fitrender_Conditions.txt';
    mappingsFile = ['bumpy',bump_level,'_5by5_correctCameraDist4DefaultMappings.txt'];
%     mappingsFile = 'bumpy5_hemilight_ortho2DefaultMappings.txt'

    % Make sure all illuminants are added to the path. 
    addpath(genpath(pwd))

    % which materials to use, [] means all
    hints.whichConditions = [];

    % Choose batch renderer options.
    hints.imageWidth = 550;
    hints.imageHeight = 550;
    datetime=datestr(now);
    datetime=strrep(datetime,':','_'); %Replace colon with underscore
    datetime=strrep(datetime,'-','_');%Replace minus sign with underscore
    datetime=strrep(datetime,' ','_');%Replace space with underscore
    hints.recipeName = ['Bump-',bump_level,'-','Gloss-',num2str(gloss_level),'-' datetime];

    ChangeToWorkingFolder(hints);

    %comment all this out
    toneMapFactor = 10;
    isScale = true;

    for renderer = {'Mitsuba'}

        % choose one renderer
        hints.renderer = renderer{1};

        % make 3 multi-spectral renderings, saved in .mat files
        nativeSceneFiles = MakeSceneFiles(parentSceneFile, conditionsFile, mappingsFile, hints);
        radianceDataFiles = BatchRender(nativeSceneFiles, hints);

        % condense multi-spectral renderings into one sRGB montage
        montageName = sprintf('Bump%s_Gloss%s_Scene4', bump_level, num2str(gloss_level));
        montageFile = [montageName '.png'];
        [SRGBMontage, XYZMontage] = ...
            MakeMontage(radianceDataFiles, montageFile, toneMapFactor, isScale, hints);

        % display the sRGB montage
        % ShowXYZAndSRGB([], SRGBMontage, montageName);
    end
end

