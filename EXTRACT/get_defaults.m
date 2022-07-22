function config = get_defaults(config)

    % General control parameters 

    if ~isfield(config, 'trace_output_option'), config.trace_output_option = 'baseline_adjusted'; end
    if ~isfield(config, 'trace_quantile'), config.trace_quantile = 0.25; end
    if ~isfield(config, 'use_gpu'), config.use_gpu = true; end
    if ~isfield(config, 'parallel_cpu'), config.parallel_cpu = false; end
    if ~isfield(config, 'dendrite_aware'), config.dendrite_aware = false; end
    if ~isfield(config, 'adaptive_kappa'), config.adaptive_kappa = 2; end
    if ~isfield(config, 'use_sparse_arrays'), config.use_sparse_arrays = false; end
    if ~isfield(config, 'hyperparameter_tuning_flag'), config.hyperparameter_tuning_flag = false; end
    if ~isfield(config, 'remove_duplicate_cells'), config.remove_duplicate_cells = true; end
    if ~isfield(config, 'max_iter'), config.max_iter = 6; end
    if ~isfield(config, 'num_iter_stop_quality_checks'), config.num_iter_stop_quality_checks = []; end
    if ~isfield(config, 'S_init'), config.S_init = []; end
    if ~isfield(config, 'T_init'), config.T_init = []; end
    if ~isfield(config, 'pre_mask_on'), config.pre_mask_on = 0; end
    if ~isfield(config, 'pre_mask_radius'), config.pre_mask_radius = 0; end
    if ~isfield(config, 'minimal_checks'), config.minimal_checks = 0; end

    % Preprocessing module parameters

    if ~isfield(config, 'preprocess'), config.preprocess = true; end
    if ~isfield(config, 'fix_zero_FOV_strips'), config.fix_zero_FOV_strips = false; end
    if ~isfield(config, 'medfilt_outlier_pixels'), config.medfilt_outlier_pixels = false; end
    if ~isfield(config, 'skip_dff'), config.skip_dff = false; end
    if ~isfield(config, 'baseline_quantile'), config.baseline_quantile = []; end
    if ~isfield(config, 'skip_highpass'), config.skip_highpass = false; end
    if ~isfield(config, 'spatial_highpass_cutoff'), config.spatial_highpass_cutoff = 5; end
    if ~isfield(config, 'temporal_denoising'), config.temporal_denoising = false; end
    if ~isfield(config, 'remove_background'), config.remove_background = false; end
    if ~isfield(config, 'second_df'), config.second_df = 0.5; end

    % Cell finding module parameters
    if ~isfield(config, 'cellfind_filter_type'), config.cellfind_filter_type = 'butter'; end
    if ~isfield(config, 'cellfind_spatial_highpass_cutoff'), config.cellfind_spatial_highpass_cutoff = inf; end
    if ~isfield(config, 'spatial_lowpass_cutoff'), config.spatial_lowpass_cutoff = 2; end
    if ~isfield(config, 'moving_radius_spatial'), config.moving_radius_spatial = 3; end
    if ~isfield(config, 'moving_radius_temporal'), config.moving_radius_temporal= 3; end
    if ~isfield(config, 'cellfind_min_snr'), config.cellfind_min_snr = 1; end
    if ~isfield(config, 'cellfind_max_steps'), config.cellfind_max_steps = 1000; end
    if ~isfield(config, 'cellfind_kappa_std_ratio'), config.cellfind_kappa_std_ratio = 0.7; end
    if ~isfield(config, 'init_with_gaussian'), config.init_with_gaussian = false; end
    if ~isfield(config, 'avg_yield_threshold'), config.avg_yield_threshold = 0.1; end

    % Visualizing cell finding module
    if ~isfield(config, 'visualize_cellfinding'), config.visualize_cellfinding = 0; end
    if ~isfield(config, 'visualize_cellfinding_show_bad_cells'), config.visualize_cellfinding_show_bad_cells = 0; end
    if ~isfield(config, 'visualize_cellfinding_full_range'), config.visualize_cellfinding_full_range = 0; end
    if ~isfield(config, 'visualize_cellfinding_min'), config.visualize_cellfinding_min = 0.2; end
    if ~isfield(config, 'visualize_cellfinding_max'), config.visualize_cellfinding_max = 0.9; end  
    


    % Cell refinement module parameters
    if ~isfield(config, 'kappa_std_ratio'), config.kappa_std_ratio = 0.7; end
    if ~isfield(config, 'thresholds')
        thresholds = [];
    else
        thresholds = config.thresholds;
    end
    
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

    % Additional parameters (will not change for 99.9% of time, no urgent need to know about them)

    if ~isfield(config, 'downsample_time_by'), config.downsample_time_by = 1; end
    if ~isfield(config, 'downsample_space_by'), config.downsample_space_by = 1; end
    if ~isfield(config, 'use_default_gpu'), config.use_default_gpu = false; end
    if ~isfield(config, 'multi_gpu'), config.multi_gpu = false; end
    if ~isfield(config, 'pick_gpu'), config.pick_gpu = []; end
    if ~isfield(config, 'min_radius_after_downsampling'), config.min_radius_after_downsampling = 5; end
    if ~isfield(config, 'min_tau_after_downsampling'), config.min_tau_after_downsampling = 5; end
    if ~isfield(config, 'reestimate_S_if_downsampled'), config.reestimate_S_if_downsampled = false; end
    if ~isfield(config, 'reestimate_T_if_downsampled'), config.reestimate_T_if_downsampled = true; end
    if ~isfield(config, 'verbose'), config.verbose = 2; end
    if ~isfield(config, 'low_cell_area_flag'), config.low_cell_area_flag = 0; end
    if ~isfield(config, 'crop_circular'), config.crop_circular = false; end
    if ~isfield(config, 'arbitrary_mask'), config.arbitrary_mask = false; end
    if ~isfield(config, 'movie_mask'), config.movie_mask = []; end
    if ~isfield(config, 'smoothing_ratio_x2y'), config.smoothing_ratio_x2y = 1; end
    if ~isfield(config, 'compact_output'), config.compact_output = 0; end
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
    if ~isfield(config, 'avg_event_tau'), config.avg_event_tau = 10; end
    if ~isfield(config, 'T_dup_thresh'), config.T_dup_thresh = 0.9; end
    if ~isfield(config, 'T_corr_thresh'), config.T_corr_thresh = 0.8; end
    if ~isfield(config, 'S_corr_thresh'), config.S_corr_thresh = 0.1; end

    % Optimizer parameters (will not change for 99.9% of time, no urgent need to know about them)
    if ~isfield(config, 'max_iter_S'), config.max_iter_S = 100; end
    if ~isfield(config, 'max_iter_T'), config.max_iter_T = 100; end
    if ~isfield(config, 'TOL_sub'), config.TOL_sub = 1e-6; end
    if ~isfield(config, 'TOL_main'), config.TOL_main = 1e-2; end
    if ~isfield(config, 'kappa_iter_nums'), config.kappa_iter_nums = []; end


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

end
