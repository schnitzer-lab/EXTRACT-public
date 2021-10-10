function config = get_defaults(config)

    % General control parameters 

    if ~isfield(config, 'trace_output_option'), config.trace_output_option = 'nonneg'; end
    if ~isfield(config, 'use_gpu'), config.use_gpu = true; end
    if ~isfield(config, 'parallel_cpu'), config.parallel_cpu = false; end
    if ~isfield(config, 'dendrite_aware'), config.dendrite_aware = false; end
    if ~isfield(config, 'adaptive_kappa'), config.adaptive_kappa = false; end
    if ~isfield(config, 'use_sparse_arrays'), config.use_sparse_arrays = false; end
    if ~isfield(config, 'hyperparameter_tuning_flag'), config.hyperparameter_tuning_flag = false; end
    if ~isfield(config, 'remove_duplicate_cells'), config.remove_duplicate_cells = true; end
    if ~isfield(config, 'max_iter'), config.max_iter = 6; end
    if ~isfield(config, 'S_init'), config.S_init = []; end
    if ~isfield(config, 'T_init'), config.T_init = []; end
    

    % Preprocessing module parameters

    if ~isfield(config, 'preprocess'), config.preprocess = true; end
    if ~isfield(config, 'fix_zero_FOV_strips'), config.fix_zero_FOV_strips = false; end
    if ~isfield(config, 'medfilt_outlier_pixels'), config.medfilt_outlier_pixels = false; end
    if ~isfield(config, 'skip_dff'), config.skip_dff = false; end
    if ~isfield(config, 'baseline_quantile'), config.baseline_quantile = 0.4; end
    if ~isfield(config, 'skip_highpass'), config.skip_highpass = false; end
    if ~isfield(config, 'spatial_highpass_cutoff'), config.spatial_highpass_cutoff = 5; end
    if ~isfield(config, 'temporal_denoising'), config.temporal_denoising = false; end
    if ~isfield(config, 'remove_background'), config.remove_background = true; end

    % Cell finding module parameters
    if ~isfield(config, 'cellfind_filter_type'), config.cellfind_filter_type = 'butter'; end
    if ~isfield(config, 'spatial_lowpass_cutoff'), config.spatial_lowpass_cutoff = 2; end
    if ~isfield(config, 'moving_radius'), config.moving_radius = 3; end
    if ~isfield(config, 'cellfind_min_snr'), config.cellfind_min_snr = 1; end
    if ~isfield(config, 'cellfind_max_steps'), config.cellfind_max_steps = 1000; end
    if ~isfield(config, 'cellfind_kappa_std_ratio'), config.cellfind_kappa_std_ratio = 1; end
    if ~isfield(config, 'init_with_gaussian'), config.init_with_gaussian = false; end


    % Cell refinement module parameters
    if ~isfield(config, 'kappa_std_ratio'), config.kappa_std_ratio = 1; end
    if ~isfield(config, 'thresholds')
        thresholds = [];
    else
        thresholds = config.thresholds;
    end
    
    if ~isfield(thresholds, 'T_min_snr'), thresholds.T_min_snr = 10; end % multiply with noise_std
    if ~isfield(thresholds, 'size_lower_limit'), thresholds.size_lower_limit = 1/10; end  % to be multipled with avg_cell_area
    if ~isfield(thresholds, 'size_upper_limit'), thresholds.size_upper_limit = 10; end  % to be multiplied with avg_cell_area
    if ~isfield(thresholds, 'temporal_corrupt_thresh'), thresholds.temporal_corrupt_thresh = 0.7; end
    if ~isfield(thresholds, 'spatial_corrupt_thresh'), thresholds.spatial_corrupt_thresh = 0.7; end
    if ~isfield(thresholds, 'eccent_thresh'), thresholds.eccent_thresh = 6; end
    if ~isfield(thresholds, 'low_ST_index_thresh'), thresholds.low_ST_index_thresh = 1e-2; end
    if ~isfield(thresholds, 'low_ST_corr_thresh'), thresholds.low_ST_corr_thresh = 0; end
    

    % Additional thresholds (not particularly/immediately relevant)
    if ~isfield(thresholds, 'T_dup_corr_thresh'), thresholds.T_dup_corr_thresh = 0.95; end
    if ~isfield(thresholds, 'S_dup_corr_thresh'), thresholds.S_dup_corr_thresh = 0.95; end
    if ~isfield(thresholds, 'confidence_thresh'), thresholds.confidence_thresh = 0.8; end
    if ~isfield(thresholds, 'high_ST_index_thresh'), thresholds.high_ST_index_thresh = 0.8; end

    % Additional parameters (will not change for 99.9% of time, no urgent need to know about them)

    if ~isfield(config, 'downsample_time_by'), config.downsample_time_by = 1; end
    if ~isfield(config, 'downsample_space_by'), config.downsample_space_by = 1; end
    if ~isfield(config, 'use_default_gpu'), config.use_default_gpu = false; end
    if ~isfield(config, 'multi_gpu'), config.multi_gpu = false; end
    if ~isfield(config, 'min_radius_after_downsampling'), config.min_radius_after_downsampling = 5; end
    if ~isfield(config, 'min_tau_after_downsampling'), config.min_tau_after_downsampling = 5; end
    if ~isfield(config, 'reestimate_S_if_downsampled'), config.reestimate_S_if_downsampled = false; end
    if ~isfield(config, 'reestimate_T_if_downsampled'), config.reestimate_T_if_downsampled = true; end
    if ~isfield(config, 'verbose'), config.verbose = 2; end
    if ~isfield(config, 'crop_circular'), config.crop_circular = false; end
    if ~isfield(config, 'movie_mask'), config.movie_mask = []; end
    if ~isfield(config, 'smoothing_ratio_x2y'), config.smoothing_ratio_x2y = 1; end
    if ~isfield(config, 'compact_output'), config.compact_output = true; end
    if ~isfield(config, 'num_frames'), config.num_frames = []; end
    if ~isfield(config, 'is_pixel_valid'), config.is_pixel_valid = []; end
    if ~isfield(config, 'save_all_found'), config.save_all_found = false; end
    if ~isfield(config, 'cellfind_numpix_threshold'), config.cellfind_numpix_threshold = 9; end  % 3x3 region
    if ~isfield(config, 'high2low_brightness_ratio'), config.high2low_brightness_ratio = inf; end
    if ~isfield(config, 'plot_loss'), config.plot_loss = false; end
    if ~isfield(config, 'l1_penalty_factor'), config.l1_penalty_factor = 0; end
    if ~isfield(config, 'T_lower_snr_threshold'), config.T_lower_snr_threshold = 10; end
    if ~isfield(config, 'smooth_T'), config.smooth_T = false; end
    if ~isfield(config, 'smooth_S'), config.smooth_S = true; end

    % Optimizer parameters (will not change for 99.9% of time, no urgent need to know about them)
    if ~isfield(config, 'max_iter_S'), config.max_iter_S = 100; end
    if ~isfield(config, 'max_iter_T'), config.max_iter_T = 100; end
    if ~isfield(config, 'TOL_sub'), config.TOL_sub = 1e-6; end
    if ~isfield(config, 'TOL_main'), config.TOL_main = 1e-2; end

    % Do not change anything below, these are no longer hyper parameter definitions!

    % If dendrites are present then don't check eccentricity
    if config.dendrite_aware
        thresholds.eccent_thresh = inf;
        thresholds.size_lower_limit = 0;
        thresholds.size_upper_limit = inf;
    end

    if config.skip_highpass
        config.spatial_highpass_cutoff=inf;
    end

    config.thresholds = thresholds;

end
