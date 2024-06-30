%% Welcome to the EXTRACT tutorial! Written by Fatih Dinc, 03/02/2021
clear
clc
M = 'neurofinder0200.h5:/data';
config=[];
config = get_defaults(config); %calls the defaults
%config.F_per_pixel = h5read('Fig4_example_final.h5','/F_per_pixel');
% Essentials, without these EXTRACT will give an error:
config.avg_cell_radius=6; 
config.preprocess = 1;
config.downsample_time_by = 6;
% The movie is small, 
% one partition should be enough!
config.cellfind_filter_type = 'butter';
config.spatial_highpass_cutoff = 8;
config.num_partitions_x=3;
config.num_partitions_y=3; 
config.compact_output = 0;
config.use_gpu = 0;
config.num_workers = 4;
config.parallel_cpu = 1;
config.cellfind_max_steps = 400;
config.cellfind_kappa_std_ratio = 1;
config.thresholds.T_min_snr = 5;
config.thresholds.spatial_corrupt_thresh = 5;
config.max_iter = 10;
config.kappa_std_ratio = 2;
config.adaptive_kappa = 2;
config.max_iter_T = 30;
config.max_iter_S = 30;
config.cellfind_max_iter = 3;
config.thresholds.size_upper_limit = 2.5; 
config.thresholds.size_lower_limit = .3; 
config.thresholds.S_dup_corr_thresh = 0.5;
config.thresholds.T_dup_corr_thresh = 0.5;

config.trace_output_option = 'no_constraint';
config.avg_yield_threshold = 0.05;
output=extractor(M,config);
save('extract_output_nf0200.mat','output','-v7.3')
%%

load('nf0200_gt.mat')
load('extract_output_nf0200.mat')
max_im = output.info.summary_image;
clim = quantile(max_im(:),[0.1,0.95]);
imshow(max_im,[clim(1) clim(2)])
plot_cells_overlay(masks,[1,0,0])
plot_cells_overlay(output.spatial_weights,[0,1,0])

S_gt = reshape(masks,512*512,[]);
S_ex = output.spatial_weights;
S_ex = reshape(S_ex,512*512,[])>0;
idx_match = match_sets(S_gt,S_ex,0.3);

%%
M = h5read('neurofinder0200.h5','/data');
load('extract_output_nf0200.mat')
cell_check(output,M);