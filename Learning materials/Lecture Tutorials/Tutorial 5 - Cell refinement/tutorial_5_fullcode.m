%% Hyperparameter tuning flag
if ~exist('jones.h5','file'),
    disp(['Downloading 2.93 GB data file jones.h5'])
    websave('jones.h5','https://wds-matlab-community-toolboxes.s3.amazonaws.com/EXTRACT/jones.h5');
end;
M = 'jones.h5:/data';
config = get_defaults([]);
config.downsample_time_by = 4;
config.spatial_lowpass_cutoff = 1;
config.use_gpu = 0;
config.hyperparameter_tuning_flag = 1;
config.cellfind_min_snr = 0;
config.thresholds.T_min_snr = 3.5;
config.cellfind_min_snr = 0;
config.adaptive_kappa = 2;
output = extractor(M,config);
plot_hyperparameter_curves(output)

%% Final extraction

M = 'jones.h5:/data';
config = get_defaults([]);
config.downsample_time_by = 4;
config.spatial_lowpass_cutoff = 1;
config.use_gpu = 0;
config.max_iter = 10;
config.cellfind_min_snr = 0;
config.thresholds.T_min_snr = 3.2;
config.thresholds.spatial_corrupt_thresh = 5;
config.thresholds.T_dup_corr_thresh = 0.8;
config.adaptive_kappa = 2;
config.kappa_std_ratio = 1;
output = extractor(M,config);
figure
plot_output_cellmap(output,[],[],'clim_scale',[0, 0.999])