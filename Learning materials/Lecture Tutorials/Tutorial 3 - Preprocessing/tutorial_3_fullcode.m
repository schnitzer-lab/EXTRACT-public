%% Create the movie
clear
clc
if ~isfile('Example_1p_movie.h5')
    [opts_2p,opts_back] = get_1p_defaults();
    opts_2p.ns = 100;
    opts_2p.n_cell = 100;
    opts_back.ns = 100;
    opts_back.n_cell = 20;
    opts_back.cell_radius = [20,40];
    rng(1)
    create_1p_movie(opts_2p,opts_back,'Example_1p_movie');
end

info = h5info('Example_1p_movie.h5');
info.Datasets.Name
info.Datasets.Dataspace

%% h5read function and watching the preprocessed movie

M = h5read('Example_1p_movie.h5','/mov', ...
    [1,1,1],[100,100,1000]);

%view_movie(M)

avg_cell_radius = 6;
spatial_highpass_cutoff = 5;
spatial_lowpass_cutoff = inf;
use_gpu = 0;
M_proc = spatial_bandpass(M, avg_cell_radius, ...
  spatial_highpass_cutoff, spatial_lowpass_cutoff, ...
  use_gpu);
%view_movie(M_proc)

figure
imshow(max(M,[],3),[])
exportgraphics(gcf,'FigA.eps','ContentType','vector')
figure
imshow(max(M_proc,[],3),[])
exportgraphics(gcf,'FigB.eps','ContentType','vector')

%% Highpass in spatial patches

M_small = h5read('Example_1p_movie.h5','/mov', ...
    [1,1,1],[50,50,1000]);
M_proc_small = spatial_bandpass(M_small, avg_cell_radius, ...
  spatial_highpass_cutoff, spatial_lowpass_cutoff, ...
  use_gpu);
%view_movie(M_proc_small)

%view_movie(M_proc(1:50,1:50,:))

%% Global preprocessing


config = get_defaults([]);
config.partition_size_time = 500;
preprocess_save('Example_1p_movie.h5:/mov',config)

%% Run EXTRACT

M = h5read('Example_1p_movie_final.h5','/mov');
config = get_defaults([]);
config.preprocess = 0;
config.use_gpu = 0;
config.cellfind_max_steps = 120;
config.thresholds.eccent_thresh = 3;
config.thresholds.size_upper_limit = 3;
config.cellfind_adaptive_kappa = 1;
config.adaptive_kappa = 2;
config.F_per_pixel = h5read('Example_1p_movie_final.h5','/F_per_pixel');
output = extractor(M,config);

a = load('Example_1p_movie.mat');

[recall,precision,ampcor,auc] = get_simulation_results(a,output);

fprintf("Prc %.3f. Rcl %.3f. Ampcor %.3f. AUC %.4f. \n", ...
    precision,recall,ampcor,auc);

S_ground = a.mov_2p.S;
T_ground = a.mov_2p.T;
[h,w,k]=size(full(output.spatial_weights));
S_ex=reshape(full(output.spatial_weights),h*w,k);
idx_match = match_sets(S_ground,S_ex,0.5); 
T_ex = output.temporal_weights';
T_ex = T_ex ./ max(T_ex,[],2);
T_ground = T_ground ./ max(T_ground,[],2);
color_extract = [0 0.4470 0.7410];
color_gt      = [144 103 167]./255;
plot_stacked_traces_double(T_ground(idx_match(1,1:11),1:1030), ...
 T_ex(idx_match(2,1:11),1:1030),1,{color_gt,color_extract},[],[],{5,3});
exportgraphics(gcf,'FigC.eps','ContentType','vector')


%% Run EXTRACT with stronger filtering

M = h5read('Example_1p_movie.h5','/mov');
config = get_defaults([]);
config.spatial_highpass_cutoff = 2;
config.use_gpu = 0;
config.cellfind_max_steps = 120;
config.thresholds.eccent_thresh = 3;
config.thresholds.size_upper_limit = 3;
config.cellfind_adaptive_kappa = 1;
config.adaptive_kappa = 2;
output = extractor(M,config);

a = load('Example_1p_movie.mat');

[recall,precision,ampcor,auc] = get_simulation_results(a,output);

fprintf("Prc %.3f. Rcl %.3f. Ampcor %.3f. AUC %.4f. \n", ...
    precision,recall,ampcor,auc);

S_ground = a.mov_2p.S;
T_ground = a.mov_2p.T;
[h,w,k]=size(full(output.spatial_weights));
S_ex=reshape(full(output.spatial_weights),h*w,k);
idx_match = match_sets(S_ground,S_ex,0.5); 
T_ex = output.temporal_weights';
T_ex = T_ex ./ max(T_ex,[],2);
T_ground = T_ground ./ max(T_ground,[],2);
color_extract = [0 0.4470 0.7410];
color_gt      = [144 103 167]./255;
plot_stacked_traces_double(T_ground(idx_match(1,1:11),1:1030), ...
 T_ex(idx_match(2,1:11),1:1030),1,{color_gt,color_extract},[],[],{5,3});
exportgraphics(gcf,'FigD.eps','ContentType','vector')

