%% Watch the processed movie first
M = h5read('jones.h5','/data');
config = get_defaults([]);
M_proc = preprocess_movie(M,config);
view_movie(M_proc(:,:,1:100))

%% Cell extraction with defaults

M = 'jones.h5:/data';
config = get_defaults([]);
config.downsample_time_by = 4;
config.use_gpu = 0;
output = extractor(M,config);
plot_output_cellmap(output,[],[],'clim_scale',[0, 0.999])

%% Redo with visualization of cell finding module
config.max_iter = 0;
config.visualize_cellfinding = 1;
output = extractor(M,config);

%% Optimized code

M = 'jones.h5:/data';
config = get_defaults([]);
config.downsample_time_by = 4;
config.spatial_lowpass_cutoff = 1;
config.use_gpu = 0;
config.max_iter = 0;
config.visualize_cellfinding = 1;
config.cellfind_min_snr = 0;
config.thresholds.T_min_snr = 3.5;
output = extractor(M,config);