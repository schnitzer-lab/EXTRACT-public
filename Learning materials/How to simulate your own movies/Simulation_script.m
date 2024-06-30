%% Create the movie
clear
clc

[opts_2p,opts_back] = get_1p_defaults();
opts_2p.ns = 100;
opts_back.ns = 100;
opts_2p.n_cell = 200;

if isfile('Example_movie.h5')
    delete('Example_movie.h5')
end
if isfile('Example_movie.mat')
    delete('Example_movie.mat')
end
create_1p_movie(opts_2p,opts_back,'Example_movie');

%% Run EXTRACT
M = h5read('Example_movie.h5','/mov');
config = get_defaults([]);
config.use_gpu = 0;
config.adaptive_kappa = 2;
config.downsample_time_by = 4;
config.max_iter = 10;
config.thresholds.size_upper_limit = 2.5;
config.cellfind_min_snr = 2;
config.trace_output_option = 'no_constraint';
output = extractor(M,config);

%% Evaluate outputs
a = load('Example_movie.mat');
mov_2p = a.mov_2p;
opts_2p = a.opts_2p;
S_ground = mov_2p.S;
T_ground = mov_2p.T;
ns = opts_2p.ns;
amps_ground = mov_2p.amplitudes;
spikes_ground = mov_2p.spikes;

S_ex = output.spatial_weights;
S_ex = reshape(S_ex,ns*ns,[]);
T_ex = output.temporal_weights';

idx_match = match_sets(S_ground,S_ex,0.8);
recall = size(idx_match,2)/size(S_ground,2);
precision = size(idx_match,2)/size(S_ex,2);

[~,~,cors_ex] = calculate_matching_amplitudes_v2(spikes_ground(idx_match(1,:)),...
            T_ground(idx_match(1,:),:),T_ex(idx_match(2,:),:));

ampcor = mean(cors_ex(~isnan(cors_ex)));

roc= compute_ROC_curve(spikes_ground(idx_match(1,:)),T_ex(idx_match(2,:),:),1);
[auc] = compute_AUC(roc);

fprintf("Prc %.3f. Rcl %.3f. Ampcor %.3f. AUC %.4f. \n", ...
    precision,recall,ampcor,auc);


%%

config.max_iter = 0;
config.S_init = S_ex;
config.adaptive_kappa = 0;
config.trace_output_option = 'least_squares';
output_ls = extractor(M,config);
T_ls = output_ls.temporal_weights';

[~,~,cors_ex] = calculate_matching_amplitudes(spikes_ground(idx_match(1,:)),...
            T_ground(idx_match(1,:),:),T_ls(idx_match(2,:),:));

ampcor = mean(cors_ex(~isnan(cors_ex)));

roc= compute_ROC_curve(spikes_ground(idx_match(1,:)),T_ls(idx_match(2,:),:),1);
[auc] = compute_AUC(roc);

fprintf("Prc %.3f. Rcl %.3f. Ampcor %.3f. AUC %.4f. \n", ...
    precision,recall,ampcor,auc);

%%

T_ground = T_ground ./ max(T_ground,[],2);
T_ex = T_ex ./ max(T_ex,[],2);
T_ls = T_ls ./ max(T_ls,[],2);

color_extract = [0 0.4470 0.7410];
color_l2     = [0.8500 0.3250 0.0980];

plot_stacked_traces_double(T_ground(idx_match(1,1:20),1:2000), ...
    T_ex(idx_match(2,1:20),1:2000),1,{'black',color_extract},[],[],{5,3});

figure
plot_stacked_traces_double(T_ground(idx_match(1,1:20),1:2000), ...
    T_ls(idx_match(2,1:20),1:2000),1,{'black',color_l2},[],[],{5,3});

