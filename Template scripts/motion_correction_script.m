%% Start the main pipeline


movie_info = h5info('example.h5','/Data');
movie_size = num2cell(movie_info.Dataspace.Size);
[nx, ny, totalnum] = deal(movie_size{:});


%% Downsample in space

% If the cells are relatively large (say larger than 6 pixel radius), you can downsample in space to decrease runtimes later on. Otherwise, skip!
downsamplespace_pipeline('example.h5:/Data',40,2,'h5',40000);
% Downsamples in space the first 40000 frames of the input movie (in h5 format) by a factor of 2, in 40 chunks.

%% Run motion correction

config_mc =[];
config_mc = get_defaults_mc(config_mc);

% By default, nonrigid correction is off. You can turn it on like this
config.nonrigid_mc=1;
run_normcorre_pipeline('example.h5:/Data','example_mc.h5:/Data',config_mc);


%% Downsample the original movie
downsampletime_pipeline('example_mc.h5:/Data',40,4,40000)
% Downsamples the first 40000 frames of the movie by 4 using 40 blocks. You can downsample the movie down to 2Hz, maybe even more...

% This concludes the preparation of the movie for cell extraction



