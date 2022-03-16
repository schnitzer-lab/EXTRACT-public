%% Start the main pipeline
%{
To aid with motion correction, we have written a wrapper around the published 
NoRMCorre (https://github.com/flatironinstitute/NoRMCorre) motion correction algorithm. 
Please download the source files of NoRMCorre (https://github.com/flatironinstitute/NoRMCorre) 
and keep them in MATLAB path if you wish to utilize our motion correction wrapper.
%}

hinfo = h5info('example.h5');
nx = hinfo.Datasets.Dataspace.Size(1);
ny = hinfo.Datasets.Dataspace.Size(2);
totalnum = hinfo.Datasets.Dataspace.Size(3);


%% Downsample in space

% If the cells are relatively large (say larger than 6 pixel radius), you can downsample in space to decrease runtimes later on. Otherwise, skip!
downsamplespace_pipeline('example.h5:/Data');
% Downsamples the movie in space by 2 in both directions

%% Run motion correction

config_mc =[];
config_mc = get_defaults_mc(config_mc);

% By default, nonrigid correction is off. You can turn it on like this
config_mc.nonrigid_mc=1;
run_normcorre_pipeline('example.h5:/Data','example_mc.h5:/Data',config_mc);


%% Downsample the original movie
downsampletime_pipeline('example_mc.h5:/Data',40,4,40000)
% Downsamples the first 40000 frames of the movie by 4 using 40 blocks. You can downsample the movie down to 2Hz, maybe even more...

% This concludes the preparation of the movie for cell extraction



