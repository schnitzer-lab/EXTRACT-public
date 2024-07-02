%% Create the movie
%clear
%clc
if ~isfile('Example_2p_movie.h5')
    [opts_2p] = get_2p_defaults();
    opts_2p.ns = 500;
    rng(1)
    create_2p_movie(opts_2p,'Example_2p_movie'); 
end
%% Run EXTRACT
M = 'Example_2p_movie.h5:/mov';
config = get_defaults([]);

% Other tutorials will explain how to tune these parameters.
config.adaptive_kappa = 2;
config.spatial_highpass_cutoff = inf;
config.downsample_time_by = 4;
config.num_partitions_x = 4;
config.num_partitions_y = 4;
config.thresholds.S_dup_corr_thresh = 0.8;
config.thresholds.T_dup_corr_thresh = 0.99;
config.thresholds.spatial_corrupt_thresh = 0.1;
config.thresholds.eccent_thresh = 3;
config.max_iter = 10;
config.thresholds.size_upper_limit = 3;
config.thresholds.size_lower_limit = .1;
config.visualize_cellfinding = 0;
config.cellfind_min_snr = 0;
config.thresholds.T_min_snr = 7;
config.verbose = 2;
config.trace_output_option = 'no_constraint';

% Change these four values to control the medium with which to run EXTRACT
config.use_gpu = 0;
config.multi_gpu = 0;
config.parallel_cpu = 1;
config.num_workers = 4;

output = extractor(M,config);

%% Evaluate outputs
a = load('Example_2p_movie.mat');

[recall,precision,ampcor,auc] = get_simulation_results(a,output);

fprintf("Prc %.3f. Rcl %.3f. Ampcor %.3f. AUC %.4f. \n", ...
    precision,recall,ampcor,auc);


