function root_folder = setup()
    % Add current directory and sample_data, layers and examples to path
    root_folder = fileparts(mfilename('fullpath'));
    addpath(root_folder);
    addpath(genpath(fullfile(root_folder, "External algorithms")));
    addpath(genpath(fullfile(root_folder, "EXTRACT")));
    addpath(genpath(fullfile(root_folder, "Learning-materials")));
end
