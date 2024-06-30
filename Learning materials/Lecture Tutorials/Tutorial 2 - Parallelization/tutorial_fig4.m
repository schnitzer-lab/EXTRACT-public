%% Welcome to the EXTRACT tutorial! Written by Fatih Dinc, 03/02/2021

M = 'neurofinder0401.h5:/data';
config=[];
config = get_defaults(config); %calls the defaults
%config.F_per_pixel = h5read('Fig4_example_final.h5','/F_per_pixel');
% Essentials, without these EXTRACT will give an error:
config.avg_cell_radius=6; 
config.preprocess = 1;
config.downsample_time_by = 3;
% The movie is small, 
% one partition should be enough!
config.num_partitions_x=2;
config.num_partitions_y=2; 
config.compact_output = 0;
config.num_workers = 1;
config.parallel_cpu = 0;
config.cellfind_max_steps = 600;
config.cellfind_kappa_std_ratio = 1;
config.dendrite_aware = 1;
config.thresholds.T_min_snr = 5;
config.thresholds.spatial_corrupt_thresh = 3;

% All the rest is to be optimized, which is the purpose of this tutorial!

output=extractor(M,config);

%%

plot_output_cellmap(output,0)
load('neurofinder_gt.mat')
plot_cells_overlay(masks,[1,0,0])


S_gt = reshape(masks,512*512,[]);
S_ex = output.spatial_weights;
S_ex = reshape(S_ex,512*512,[])>0;
idx_match = match_sets(S_gt,S_ex,0.01);
