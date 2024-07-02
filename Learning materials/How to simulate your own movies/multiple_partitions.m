%% Run EXTRACT
M = 'Example_2p_movie.h5:/mov';
config = get_defaults([]);
config.use_gpu = 0;
config.adaptive_kappa = 2;
config.spatial_highpass_cutoff = inf;
%config.parallel_cpu = 1;
%config.num_workers = 4;
config.downsample_time_by = 4;
config.num_partitions_x = 2;
config.num_partitions_y = 2;
config.thresholds.S_dup_corr_thresh = 0.8;
config.thresholds.T_dup_corr_thresh = 0.99;
config.max_iter = 10;
config.thresholds.size_upper_limit = 2;
config.thresholds.size_lower_limit = .3;
config.visualize_cellfinding = 0;
config.cellfind_min_snr = 2;
config.thresholds.T_min_snr = 7;
config.verbose = 2;
config.trace_output_option = 'no_constraint';
output = extractor(M,config);

%% Evaluate outputs
a = load('Example_2p_movie.mat');
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

idx_match = match_sets(S_ground,S_ex,0.5);
recall = size(idx_match,2)/size(S_ground,2);
precision = size(idx_match,2)/size(S_ex,2);

[~,~,cors_ex] = calculate_matching_amplitudes(spikes_ground(idx_match(1,:)),...
            T_ground(idx_match(1,:),:),T_ex(idx_match(2,:),:));

ampcor = mean(cors_ex(~isnan(cors_ex)));

%roc= compute_ROC_curve(spikes_ground(idx_match(1,:)),T_ex(idx_match(2,:),:),1);
%[auc] = compute_AUC(roc);
auc = 0;
fprintf("Prc %.3f. Rcl %.3f. Ampcor %.3f. AUC %.4f. \n", ...
    precision,recall,ampcor,auc);

error('stop')
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

