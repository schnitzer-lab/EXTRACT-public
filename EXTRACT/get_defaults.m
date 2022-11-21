function config = get_defaults(config)

% General control parameters 
defaults.trace_output_option = 'baseline_adjusted';
defaults.avg_cell_radius = 6;
defaults.trace_quantile = .25;
defaults.use_gpu = true;
defaults.parallel_cpu = false;
defaults.dendrite_aware = false;
defaults.adaptive_kappa = 2;
defaults.use_sparse_arrays = false;
defaults.hyperparameter_tuning_flag = false;
defaults.remove_duplicate_cells = true;
defaults.max_iter = 6;
defaults.num_iter_stop_quality_checks = [];
defaults.S_init = [];
defaults.T_init = [];
defaults.pre_mask_on = 0;
defaults.pre_mask_radius = 0;
defaults.minimal_checks = 0;


% Pre processing module parameters
defaults.preprocess = true;
defaults.fix_zero_FOV_strips = false;
defaults.medfilt_outlier_pixels = false;
defaults.skip_dff = false;
defaults.baseline_quantile = [];
defaults.skip_highpass = false;
defaults.spatial_highpass_cutoff = 5;
defaults.temporal_denoising = false;
defaults.remove_background = false;
defaults.second_df = .5;


% Cell finding module parameters
defaults.cellfind_filter_type = 'butter';
defaults.cellfind_spatial_highpass_cutoff = inf;
defaults.spatial_lowpass_cutoff = 2;

defaults.spatial_lowpass_cutoff= 2; 
defaults.moving_radius_spatial = 3; 
defaults.moving_radius_temporal = 3; 
defaults.cellfind_min_snr = 1; 
defaults.cellfind_max_steps = 1000; 
defaults.cellfind_kappa_std_ratio = 0.7; 
defaults.cellfind_adaptive_kappa = 1; 
defaults.init_with_gaussian = false; 
defaults.avg_yield_threshold = 0.1; 

% Visualizing cell finding module
defaults.visualize_cellfinding = 0; 
defaults.visualize_cellfinding_show_bad_cells = 0; 
defaults.visualize_cellfinding_full_range = 0; 
defaults.visualize_cellfinding_min = 0.2; 
defaults.visualize_cellfinding_max = 0.9;   



% Cell refinement module parameters
defaults.kappa_std_ratio = 0.7; 
defaults.thresholds = struct;



% Additional parameters (will not change for 99.9% of time, no urgent need to know about them)
defaults.downsample_time_by = 1; 
defaults.downsample_space_by = 1; 
defaults.use_default_gpu = false; 
defaults.multi_gpu = false; 
defaults.pick_gpu = []; 
defaults.min_radius_after_downsampling = 5; 
defaults.min_tau_after_downsampling = 5; 
defaults.reestimate_S_if_downsampled = false; 
defaults.reestimate_T_if_downsampled = true; 
defaults.verbose = 2; 
defaults.low_cell_area_flag = 0; 
defaults.crop_circular = false; 
defaults.arbitrary_mask = false; 
defaults.movie_mask = []; 
defaults.smoothing_ratio_x2y = 1; 
defaults.compact_output= 0; 
defaults.num_frames = []; 
defaults.is_pixel_valid = []; 
defaults.save_all_found = false; 
defaults.cellfind_numpix_threshold = 9;   % 3x3 region
defaults.high2low_brightness_ratio = inf; 
defaults.plot_loss = false; 
defaults.l1_penalty_factor = 0; 
defaults.T_lower_snr_threshold = 10; 
defaults.smooth_T = false; 
defaults.smooth_S = true; 
defaults.avg_event_tau = 10; 
defaults.T_dup_thresh = 0.9; 
defaults.T_corr_thresh = 0.8; 
defaults.S_corr_thresh = 0.1; 

% Optimizer parameters (will not change for 99.9% of time, no urgent need to know about them)
defaults.cellfind_max_iter = 10; 
defaults.max_iter_S= 100; 
defaults.max_iter_T = 100; 
defaults.max_iter_T_final = 100; 
defaults.TOL_sub = 1e-6; 
defaults.TOL_main = 1e-2; 
defaults.kappa_iter_nums = []; 
defaults.skip_parpool_calculations = false; 

if nargin == 0 || isempty(config)
    % no argument, use defaults
    config = defaults;
else
    % some params provided, use those.
    param_names = fieldnames(defaults);
    for i = 1:length(param_names)
        if isfield(config,param_names{i})
            defaults.(param_names{i}) = config.(param_names{i});
        end
    end

    % swap
    config = defaults;
end

thresholds = config.thresholds;


if ~isfield(thresholds, 'T_min_snr'), thresholds.T_min_snr = 7; end % multiply with noise_std
if ~isfield(thresholds, 'size_lower_limit'), thresholds.size_lower_limit = 1/10; end  % to be multipled with avg_cell_area
if ~isfield(thresholds, 'size_upper_limit'), thresholds.size_upper_limit = 10; end  % to be multiplied with avg_cell_area
if ~isfield(thresholds, 'temporal_corrupt_thresh'), thresholds.temporal_corrupt_thresh = 0.7; end
if ~isfield(thresholds, 'spatial_corrupt_thresh'), thresholds.spatial_corrupt_thresh = 1.5; end
if ~isfield(thresholds, 'eccent_thresh'), thresholds.eccent_thresh = 6; end
if ~isfield(thresholds, 'low_ST_index_thresh'), thresholds.low_ST_index_thresh = 1e-2; end
if ~isfield(thresholds, 'low_ST_corr_thresh'), thresholds.low_ST_corr_thresh = 0; end


% Additional thresholds (not particularly/immediately relevant)
if ~isfield(thresholds, 'T_dup_corr_thresh'), thresholds.T_dup_corr_thresh = 0.95; end
if ~isfield(thresholds, 'S_dup_corr_thresh'), thresholds.S_dup_corr_thresh = 0.95; end
if ~isfield(thresholds, 'confidence_thresh'), thresholds.confidence_thresh = 0.8; end
if ~isfield(thresholds, 'high_ST_index_thresh'), thresholds.high_ST_index_thresh = 0.8; end

% Do not change anything below, these are no longer hyper parameter definitions!

% If dendrites are present then don't check eccentricity
if config.dendrite_aware
    thresholds.eccent_thresh = inf;
    thresholds.size_lower_limit = 0;
    thresholds.size_upper_limit = inf;
end

if config.hyperparameter_tuning_flag
    config.trace_output_option = 'None';
end

if config.skip_highpass
    config.spatial_highpass_cutoff=inf;
end

if config.minimal_checks
    %thresholds.T_min_snr = 3.5; It is a better idea to pick T_min_snr externally!
    thresholds.size_upper_limit = inf;
    thresholds.eccent_thresh = inf;
    thresholds.spatial_corrupt_thresh = inf;
    thresholds.low_ST_index_thresh = -1;
end

config.thresholds = thresholds;

