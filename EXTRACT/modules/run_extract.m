function [S, T, summary] = run_extract(M, config)
% Find spatial (S) and temporal (T) matrices via robust estimation
%  using one-sided Huber loss.
%   M: 3-D movie matrix
%   config: Matlab struct containing algorithm paramteters as fields
% Returns:
%   S: Updated spatial components matrix
%   T: Updated temporal components matrix
%   summary: Matlab struct containing a useful summary of the algorithm


start_preprocess= posixtime(datetime);

ABS_TOL = 1e-6;

M = single(M);

fov_size = [];
[fov_size(1), fov_size(2), n] = size(M);
script_log = '';

% We use the user defined average time constant
%str = sprintf('\t \t \t Estimating the average time constant...\n');
%script_log = [script_log, str];
%dispfun(str, config.verbose ==2);
%tau = estimate_tau(reshape(M, fov_size(1) * fov_size(2), n));
% Quit if no activity is found
%if tau == 0
%    str = sprintf('\t \t \t No signal detected, terminating...\n');
%    script_log = [script_log, str];
%    dispfun(str, config.verbose ==2);
%    S = [];
%    T = [];
%    summary.log = script_log;
%    return;
%end
%config.avg_event_tau = tau;

tau = config.avg_event_tau;

% Space downsampling
dss = config.downsample_space_by;
if strcmp(dss, 'auto') || isempty(dss)
    dss = max(round(config.avg_cell_radius ...
        / config.min_radius_after_downsampling), 1);
end
config.downsample_space_by = dss;
if dss > 1
    M_before_dss = M;
    M = downsample_space(M, dss);
    [fov_size(1), fov_size(2), n] = size(M);
end

config.avg_cell_radius = config.avg_cell_radius / dss;


if ((~config.preprocess) && (~isfield(config, 'F_per_pixel'))) 
    warning(['The baseline values for the pre-processed movie are missing, assuming the movie is dfofed...']);
    config.F_per_pixel = ones(fov_size(1),fov_size(2));
end

if ~config.preprocess
    str = sprintf('\t \t \t Using the provided pre-processed movie...\n');
    script_log = [script_log, str]; 
    dispfun(str, config.verbose ==2);

else

    % Preprocess movie
    str = sprintf('\t \t \t Preprocessing movie...\n');
    script_log = [script_log, str];
    dispfun(str, config.verbose ==2);
    [M, config] = preprocess_movie(M, config);
end

max_image = max(M, [], 3);



% Time downsampling
dst = config.downsample_time_by;
if strcmp(dst, 'auto') || isempty(dst)
    dst = max(round(tau / config.min_tau_after_downsampling), 1);
end
config.downsample_time_by = dst;
if dst > 1
    % Save full resolution movie if full T will be re-estimated
    if config.reestimate_T_if_downsampled
        M_before_dst = reshape(M, fov_size(1) * fov_size(2), n);
    end
    M = downsample_time(M, dst);
    n_orig = n;
    [fov_size(1), fov_size(2), n] = size(M);
end

% Get pixels of the movie with signal
M = reshape(M, fov_size(1) * fov_size(2), n);
config.is_pixel_valid = std(M, 1, 2) > ABS_TOL;
M = reshape(M, fov_size(1), fov_size(2), n);

time_summary.preprocess = posixtime(datetime)-start_preprocess;

start_cellfinding = posixtime(datetime);

% Cell finding
if isempty(config.S_init)
    % Initialization using component-wise EXTRACT
    str = sprintf('\t \t \t Finding cells with component-wise EXTRACT...\n');
    script_log = [script_log, str];
    dispfun(str, config.verbose ==2);
    [S, T, init_summary] = cw_extract(M, config);
    summary_image = init_summary.summary_im;
    if config.save_all_found
        summary.S_found = S;
        summary.T_found = T;
    end
elseif isempty(config.T_init)
    % Use given S -- ensure nonnegativity & correct scale
    if dss > 1
        [fov_y, fov_x, ~] = size(M_before_dss);
    else
        [fov_y, fov_x, ~] = size(M);
    end
    if size(config.S_init, 1) ~= fov_y * fov_x
        error(['Size of the provided cell images',...
            ' don''t match the size of the FOV.']);
    end
    S = full(max(config.S_init, 0));
    S(:,sum(S,1)==0)=[];
    S = normalize_to_one(S);
    str = sprintf('\t \t \t Initializing using provided images (%d cells)...\n',size(S,2));
    script_log = [script_log, str];
    dispfun(str, config.verbose ==2);
    % Downsample if needed
    if dss > 1
        S = reshape(S, fov_y, fov_x, size(S, 2));
        S = downsample_space(S, dss);
        S = reshape(S, fov_size(1) * fov_size(2), size(S, 3));
    end
    % Do nonnegative least-squares fit to find T
    M = reshape(M, fov_size(1) * fov_size(2), n);
    T = zeros(size(S, 2), n);

    noise_ls_temp = estimate_noise_std(M,2);
    if ~isempty(config.movie_mask)
        noise_ls_temp = noise_ls_temp(config.movie_mask(:));
    end
    noise_ls_temp = median(noise_ls_temp);

    try
        [T, ~, ~, ~, ~] = solve_T(T, S, M, fov_size, config.avg_cell_radius, T(:, 1)' * 0, ...
                noise_ls_temp*10, config.max_iter_T, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu, 0);
    catch
        [T, ~, ~, ~, ~] = solve_T(T, S, M, fov_size, config.avg_cell_radius, T(:, 1)' * 0, ...
                noise_ls_temp*10, config.max_iter_T, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu, 0,30);
    end

    
    init_summary = 'external init';
    M = reshape(M, fov_size(1), fov_size(2), n);
    summary_image = max(M, [], 3);
else
    if dss > 1
        [fov_y, fov_x, fov_z] = size(M_before_dss);
    else
        [fov_y, fov_x, fov_z] = size(M);
    end
    if size(config.S_init, 1) ~= fov_y * fov_x
        error(['Size of the provided cell images',...
            ' don''t match the size of the FOV.']);
    end
    S = full(max(config.S_init, 0));
    S = normalize_to_one(S);
    str = sprintf('\t \t \t Initializing using provided images and traces (%d cells)...\n',size(S,2));
    script_log = [script_log, str];
    dispfun(str, config.verbose ==2);
    % Use given S -- ensure nonnegativity & correct scale
    % Downsample if needed
    if dss > 1
        S = reshape(S, fov_y, fov_x, size(S, 2));
        S = downsample_space(S, dss);
        S = reshape(S, fov_size(1) * fov_size(2), size(S, 3));
    end
    if size(config.T_init, 2) ~= fov_z
        error(['Size of the provided cell traces',...
            ' don''t match the duration of the movie.']);
    end
    if size(config.T_init, 1) ~= size(config.S_init, 2)
        error(['Number of cells in the provided cell traces',...
            ' don''t match the cell images.']);
    end
    T=max(config.T_init,0);
    init_summary = 'external init';
    M = reshape(M, fov_size(1), fov_size(2), n);
    summary_image = max(M, [], 3);
end

clims_visualize = quantile(summary_image(:), [config.visualize_cellfinding_min config.visualize_cellfinding_max]);


% Update avg_radius given init images (given top 10% brightest cells)
num_selected = ceil(size(S, 2)*0.1);
% Use at least 5 cells (or the # of init components if fewer)
num_selected = min(size(S, 2), max(5, num_selected));
avg_radius_estimate = estimate_avg_radius(S(:, 1:num_selected), fov_size);
% avg_radius is the mean of the estimate and user-provided radius
avg_radius = (avg_radius_estimate + config.avg_cell_radius) / 2;
config.avg_cell_radius = avg_radius;

% Reshape M to 2-D
M = reshape(M, fov_size(1) * fov_size(2), n);

% Transpose M for better spatial slicing
Mt = M';

% Algorithm parameters
ABS_TOL = 1e-6;

% Estimate noise std
% Use the noise std estimate from cell finding if it exists & there was no
% spatial lowpass filtering
if isempty(config.S_init) && strcmpi(config.cellfind_filter_type, 'none')
    noise_per_pixel = init_summary.noise_per_pixel;
else
    noise_per_pixel = estimate_noise_std(Mt, 1, config.use_gpu);
    % Apply movie mask to noise if it exists
    if ~isempty(config.movie_mask)
        noise_per_pixel = noise_per_pixel(config.movie_mask(:));
    end
end
ind = (noise_per_pixel > 1e-12);
noise_std = median(noise_per_pixel(ind));


avg_cell_area = pi * avg_radius ^ 2;
% Update thresholds with data collected
config.thresholds.size_lower_limit = config.thresholds.size_lower_limit * avg_cell_area;
config.thresholds.size_upper_limit = config.thresholds.size_upper_limit * avg_cell_area;

kappa = config.kappa_std_ratio * noise_std;
mask_extension_radius = round(avg_radius*1);
classification = [];  % Updated during redundant cell check

% Use adaptive regression routine if asked
if config.adaptive_kappa == 2
    fp_solve_func = @fp_solve_adaptive;
else
    fp_solve_func = @fp_solve_admm;
end

% Initialize variables
S_smooth = S;
S_loss = [];
T_loss = [];
S_bad = [];
T_bad = [];
last_size = 0;

% Summary variables
num_init_comp = size(S,2);
S_change = zeros(num_init_comp, config.max_iter, 'single');
T_change = zeros(num_init_comp, config.max_iter, 'single');

if config.max_iter > 0
    str = sprintf('\t \t \t Updating S and T with alternating estimation...\n');
    script_log = [script_log, str];
    dispfun(str, config.verbose ==2);
else
    str = sprintf('\t \t \t Skipping cell refinement module...\n');
    script_log = [script_log, str];
    dispfun(str, config.verbose ==2);

end

if config.pre_mask_on
    if config.pre_mask_radius == 0
        mask = S > 0;
    else
        try
            mask = make_mask(maybe_gpu(config.use_gpu, single(S > 0)), ...
                fov_size, config.pre_mask_radius);
        catch
            mask = make_mask(maybe_gpu(0, single(S > 0)), ...
                fov_size, config.pre_mask_radius);
        end
    end
end


time_summary.cellfinding = posixtime(datetime)-start_cellfinding;

start_cellrefinement = posixtime(datetime);

for iter = 1:config.max_iter
	%---
    % Update T
    %---
    % Quit if no cells left
    if isempty(T)
        str = sprintf('\t \t \t Zero cells, stopping. \n');
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
        config.trace_output_option = 'none';
        config.reestimate_T_if_downsampled = 0;
        break;
    end
    T_before = T;
    % compute l1 penalty constants
    if config.l1_penalty_factor > ABS_TOL
        % Penalize according to temporal overlap with neighbors
        cor = get_comp_corr(S, T);
        lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
            * config.l1_penalty_factor;
    else
        lambda = T(:, 1)' * 0;
    end

    try

    [T, loss, np_x, np_y, np_time] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
            kappa, config.max_iter_T, config.TOL_sub, ...
            config.plot_loss, fp_solve_func, config.use_gpu, 1);
    catch
    [T, loss, np_x, np_y, np_time] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
            kappa, config.max_iter_T, config.TOL_sub, ...
            config.plot_loss, fp_solve_func, config.use_gpu, 1,30);
    

    end

    % Update T_loss
    T_loss = [T_loss, loss]; %#ok<*AGROW>
    % Compute T_smooth
    
    if config.smooth_T
        T = smooth_traces(T, 1);
    end
    % Compute the mean absolute change from last iteration
    T_change(:, iter) =  sqrt(sum((T - T_before).^2, 2) ./ sum(T_before.^2, 2));
    
    % Plot progress
    if config.plot_loss
        plot_func(T_loss, 1, iter, size(T, 1));
    end
    % T-step summary
    if config.verbose == 2
        %fprintf(repmat('\b', 1, last_size));
        str = sprintf('\t \t \t T-step # %d: %d cells (npx:%d, npy:%d, npt:%d) \n', ...
            iter, size(T, 1), np_x, np_y, np_time);
        last_size = length(str);
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
    end

    %---
    % Update S
    %---
    % Quit if no cells left
    if isempty(T)
        str = sprintf('\t \t \t Zero cells, stopping. \n');
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
        config.trace_output_option = 'none';
        config.reestimate_T_if_downsampled = 0;
        break;
    end
    % Update spatial binary mask
    if (~config.pre_mask_on)
        try
        mask = make_mask(maybe_gpu(config.use_gpu, single(S_smooth > 0.1)), ...
            fov_size, mask_extension_radius);
        catch
        mask = make_mask(maybe_gpu(0, single(S_smooth > 0.1)), ...
            fov_size, mask_extension_radius);
        end
    end
    
    % Update S
    S_before = S;
    lambda = S(1,:)*0;

    if config.adaptive_kappa_filter
        try

        [S, loss, np_x, np_y, T_corr_in, T_corr_out, S_surround] = solve_S(...
            S, T, Mt, mask, fov_size, avg_radius, ...
                lambda, kappa, config.max_iter_S, config.TOL_sub, ...
                config.plot_loss, @fp_solve_adaptive_filter, config.use_gpu);

        catch
        
        [S, loss, np_x, np_y, T_corr_in, T_corr_out, S_surround] = solve_S(...
            S, T, Mt, mask, fov_size, avg_radius, ...
                lambda, kappa, config.max_iter_S, config.TOL_sub, ...
                config.plot_loss, @fp_solve_adaptive_filter, config.use_gpu,50);
        
        end

    else
        try

        [S, loss, np_x, np_y, T_corr_in, T_corr_out, S_surround] = solve_S(...
            S, T, Mt, mask, fov_size, avg_radius, ...
                lambda, kappa, config.max_iter_S, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu);

        catch
        
        [S, loss, np_x, np_y, T_corr_in, T_corr_out, S_surround] = solve_S(...
            S, T, Mt, mask, fov_size, avg_radius, ...
                lambda, kappa, config.max_iter_S, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu,50);
        
        end

    end

    if config.low_cell_area_flag
        S_smooth = smooth_images(S, fov_size,...
            round(avg_radius / 3), config.use_gpu, false);
    else
        S_smooth = smooth_images(S, fov_size,...
            round(avg_radius / 2), config.use_gpu, true);
    end
    S_smooth = normalize_to_one(S_smooth);
    S_loss = [S_loss, loss];
    % Compute the mean absolute change from last iteration
    S_change(:, iter) = sqrt(sum((S - S_before).^2, 1)' ./ sum(S_before.^2, 1)');

    % Plot progress
    if config.plot_loss
        plot_func(S_loss, 0, iter, size(S,2));
    end
    % S-step summary
    if config.verbose == 2
        fprintf(repmat('\b', 1, last_size));
        str = sprintf('\t \t \t S-step # %d: %d cells (npx:%d, npy:%d)\n', ...
            iter, size(S, 2), np_x, np_y);
        last_size = length(str);
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
    end

    if (config.hyperparameter_tuning_flag==1)
    [classification] = classification_hyperparameters(...
                classification, S, S_smooth, T, M, S_surround, T_corr_in, T_corr_out, fov_size, round(avg_radius), ...
                config.use_gpu);
    
	str = sprintf('\t \t \t Terminating the cell-refinement for hyperparameter tuning \n');
	dispfun(str, config.verbose ==2);
	break
    end

    if( ismember(iter,config.num_iter_stop_quality_checks))

        if (iter == config.max_iter)
            [classification] = classification_hyperparameters(...
                classification, S, S_smooth, T, M, S_surround, T_corr_in, T_corr_out, fov_size, round(avg_radius), ...
                config.use_gpu);
        end

        if config.verbose == 2
            fprintf(repmat('\b', 1, last_size));
            str = sprintf('\t \t \t End of iter # %d: # cells: %d (no quality checks) \n', ...
                iter, size(T, 1));
            last_size = length(str);
            script_log = [script_log, str];
            dispfun(str, config.verbose ==2);
        end

        if config.visualize_cellfinding
            
            subplot(121)
            clf
            
            imshow(summary_image,clims_visualize)
            
            plot_cells_overlay(reshape(gather(S),fov_size(1),fov_size(2),size(S,2)),[0,1,0],[])
            title(['Cell refinement step: ' num2str(iter) ' # Cells: ' num2str(size(T,1)) ' # Removed: 0'  ])
            drawnow;
        end


        continue

    end

    %---
    % Remove redundant cells
    %---
    if mod(iter, 1) == 0
        % Identify cells to be deleted
        [classification, is_bad] = remove_redundant(...
                classification, S, S_smooth, T, M, S_surround, T_corr_in, T_corr_out, fov_size, round(avg_radius), ...
                config.use_gpu, config.thresholds,config.use_sparse_arrays);
		

        % Merge duplicate cells (update images)
        if ~isempty(classification(end).merge.idx_merged)
            [S, T] = update_merged_images(S, T, S_smooth, classification(end).merge);
            % Recalculate smooth images for merged ones
            S_smooth(:, classification(end).merge.idx_merged) = smooth_images(...
                S(:, classification(end).merge.idx_merged), fov_size,...
                round(avg_radius / 3), config.use_gpu, true);
            S_smooth = normalize_to_one(S_smooth);
        end
         
        % Delete bad cells
        S_bad = [S(:, is_bad), S_bad];
        T_bad = [T(is_bad, :); T_bad];
        if config.pre_mask_on
            mask(:,is_bad) = [];
        end

        [S, S_smooth] = delete_columns(is_bad, S, S_smooth);
        [T, T_change, S_change] = delete_rows(is_bad, T, T_change, S_change);
        if config.verbose == 2
            fprintf(repmat('\b', 1, last_size));
            str = sprintf('\t \t \t End of iter # %d: # cells: %d (%d removed) \n', ...
                iter, size(T, 1), sum(is_bad));
            last_size = length(str);
            script_log = [script_log, str];
            dispfun(str, config.verbose ==2);
        end

        if config.visualize_cellfinding
            
            subplot(121)
            clf
            imshow(summary_image,clims_visualize)
            plot_cells_overlay(reshape(gather(S),fov_size(1),fov_size(2),size(S,2)),[0,1,0],[])
            title(['Cell refinement step: ' num2str(iter) ' # Cells: ' num2str(size(T,1)) ' # Removed: ' num2str(sum(is_bad)) ])
            drawnow;
        end

    end
    if config.smooth_S, S = S_smooth; end

    %---
    % Stopping criterion
    %---
    if  iter> 1 && ~isempty(S_change) && ...
        (max(S_change(:, iter))< config.TOL_main) && ...
        (max(T_change(:, iter))< config.TOL_main)
        str = sprintf('\t \t \t Stopping due to early convergence. \n');
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
        config.trace_output_option = 'none';
        config.reestimate_T_if_downsampled = 0;
        break;
    end
end


time_summary.cellrefinement = posixtime(datetime)-start_cellrefinement;

start_frr = posixtime(datetime);

% A final check before final robust regression
if isempty(T)
    config.trace_output_option = 'none';
    config.reestimate_T_if_downsampled = 0;
end

if dst > 1  && config.reestimate_T_if_downsampled 
    trace_temp_opt = config.trace_output_option;
    config.trace_output_option = 'none';
end

switch config.trace_output_option
    case 'no_constraint'
        str = sprintf('\t \t \t Providing traces with robust regression and no non-negativity constraint... \n');
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
        
        if config.l1_penalty_factor > ABS_TOL
            % Penalize according to temporal overlap with neighbors
            cor = get_comp_corr(S, T);
            lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                * config.l1_penalty_factor;
        else
            lambda = T(:, 1)' * 0;
        end
        if config.adaptive_kappa > 0
            try 
                [T, ~, ~, ~, ~] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                    kappa, config.max_iter_T_final, config.TOL_sub, ...
                    config.plot_loss, @fp_solve_adaptive_raw, config.use_gpu, 1);
            catch 
                    [T, ~, ~, ~, ~] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa, config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve_adaptive_raw, config.use_gpu, 1,30);
            end
            else

            try 
                [T, ~, ~, ~, ~] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                    kappa, config.max_iter_T_final, config.TOL_sub, ...
                    config.plot_loss, @fp_solve, config.use_gpu, 1);
            catch 
                    [T, ~, ~, ~, ~] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa, config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve, config.use_gpu, 1,30);
            end
        end

    case 'baseline_adjusted'
        
        
        if config.l1_penalty_factor > ABS_TOL
            % Penalize according to temporal overlap with neighbors
            cor = get_comp_corr(S, T);
            lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                * config.l1_penalty_factor;
        else
            lambda = T(:, 1)' * 0;
        end
        if config.adaptive_kappa > 0
            str = sprintf('\t \t \t Providing baseline adjusted traces with adaptive kappa... \n');
            script_log = [script_log, str];
            dispfun(str, config.verbose ==2);
            try 
                [T, ~, ~, ~, ~] = solve_T_robust(T, S, Mt, fov_size, avg_radius, lambda, ...
                    kappa, config.max_iter_T_final, config.frr_check_every_step, ...
                    config.plot_loss, config.trace_quantile, config.use_gpu, 1,@fp_solve_adaptive_baseline,4,config.kappa_iter_nums,config.frr_edge_case_flag);
            catch
                [T, ~, ~, ~, ~] = solve_T_robust(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa, config.max_iter_T_final, config.frr_check_every_step, ...
                config.plot_loss, config.trace_quantile, config.use_gpu, 1,@fp_solve_adaptive_baseline,30,config.kappa_iter_nums,config.frr_edge_case_flag);
            end
        else
            str = sprintf('\t \t \t Providing baseline adjusted traces with a fixed kappa of %.1f... \n',config.kappa_std_ratio);
            script_log = [script_log, str];
            dispfun(str, config.verbose ==2);
            try
                [T, ~, ~, ~, ~] = solve_T_robust(T, S, Mt, fov_size, avg_radius, lambda, ...
                    kappa, config.max_iter_T_final, config.frr_check_every_step, ...
                    config.plot_loss, config.trace_quantile, config.use_gpu, 1,@fp_solve_admm_baseline,4,[],config.frr_edge_case_flag);
            catch
                [T, ~, ~, ~, ~] = solve_T_robust(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa, config.max_iter_T_final, config.frr_check_every_step, ...
                config.plot_loss, config.trace_quantile, config.use_gpu, 1,@fp_solve_admm_baseline,30,[],config.frr_edge_case_flag);
            end
        end

        T = T - min(T,[],2);
            
    case 'nonneg'
        if config.l1_penalty_factor > ABS_TOL
            % Penalize according to temporal overlap with neighbors
            cor = get_comp_corr(S, T);
            lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                * config.l1_penalty_factor;
        else
            lambda = T(:, 1)' * 0;
        end
        if config.adaptive_kappa > 0
            str = sprintf('\t \t \t Providing non-negative traces with adaptive kappa... \n');
            script_log = [script_log, str];
            dispfun(str, config.verbose ==2);
            try
                [T, loss, np_x, np_y, np_time] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa, config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve_adaptive, config.use_gpu, 1);
            catch
                [T, loss, np_x, np_y, np_time] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa, config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve_adaptive, config.use_gpu, 1,30);
            end
        else
            str = sprintf('\t \t \t Providing non-negative traces with a fixed kappa of %.1f... \n',config.kappa_std_ratio);
            script_log = [script_log, str];
            dispfun(str, config.verbose ==2);
            try
                [T, loss, np_x, np_y, np_time] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa, config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu, 1);
            catch
                [T, loss, np_x, np_y, np_time] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa, config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu, 1,30);  
            end  
        end


    case 'nonnegative_least_squares'
        str = sprintf('\t \t \t Providing nonnegative least squares traces... \n');
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
        if (config.max_iter == 0)
            if config.l1_penalty_factor > ABS_TOL
                % Penalize according to temporal overlap with neighbors
                cor = get_comp_corr(S, T);
                lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                    * config.l1_penalty_factor;
            else
                lambda = T(:, 1)' * 0;
            end
            try
                [T, loss, np_x, np_y, np_time] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa * (100/config.kappa_std_ratio), config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu, 1);
            catch
                [T, loss, np_x, np_y, np_time] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa * (100/config.kappa_std_ratio), config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu, 1,30);
            end

        end
    case 'least_squares'
        str = sprintf('\t \t \t Providing least squares traces... \n');
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
        
        if config.l1_penalty_factor > ABS_TOL
            % Penalize according to temporal overlap with neighbors
            cor = get_comp_corr(S, T);
            lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                * config.l1_penalty_factor;
        else
            lambda = T(:, 1)' * 0;
        end

        try
            [T, ~, ~, ~, ~] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa * (100/config.kappa_std_ratio), config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve, config.use_gpu, 1);
        catch
            [T, ~, ~, ~, ~] = solve_T(T, S, Mt, fov_size, avg_radius, lambda, ...
                kappa * (100/config.kappa_std_ratio), config.max_iter_T_final, config.TOL_sub, ...
                config.plot_loss, @fp_solve, config.use_gpu, 1,30);
        end
end

clear M Mt;



% Estimate full T if time was downsampled
if dst > 1 
    if ~isempty(S)
        str = sprintf('\t \t \t Re-estimating T for all frames... \n');
        script_log = [script_log, str];
        dispfun(str, config.verbose ==2);
        % Interpolate T to get an initial estimate for the full range
        Tt = interp1(round(linspace(1, n_orig, n)), T', 1:n_orig);
        % Tt comes out as row vector when # of components = 1 - Fix it:
        if size(Tt, 1) == 1, Tt = Tt'; end
        if config.reestimate_T_if_downsampled
            config.trace_output_option = trace_temp_opt;
            % Update kappa according to dst
            kappa = kappa * sqrt(dst);

            % Respect the final regression algorithm choice
            T = Tt';
            switch config.trace_output_option
                case 'no_constraint'
                    %str = sprintf('\t \t \t Providing raw traces. \n');
                    %script_log = [script_log, str];
                    %dispfun(str, config.verbose ==2);
                    
                    if config.l1_penalty_factor > ABS_TOL
                        % Penalize according to temporal overlap with neighbors
                        cor = get_comp_corr(S, T);
                        lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                            * config.l1_penalty_factor;
                    else
                        lambda = T(:, 1)' * 0;
                    end

                    if config.adaptive_kappa > 0
                        try
                            [T, ~, ~, ~, ~] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.TOL_sub, ...
                                config.plot_loss, @fp_solve_adaptive_raw, config.use_gpu, 0);
                        catch
                            [T, ~, ~, ~, ~] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.TOL_sub, ...
                                config.plot_loss, @fp_solve_adaptive_raw, config.use_gpu, 0,30);
                        end
                    
                    else

                        try
                            [T, ~, ~, ~, ~] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.TOL_sub, ...
                                config.plot_loss, @fp_solve, config.use_gpu, 0);
                        catch
                            [T, ~, ~, ~, ~] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.TOL_sub, ...
                                config.plot_loss, @fp_solve, config.use_gpu, 0,30);
                        end
                    end

                case 'baseline_adjusted'
                    %str = sprintf('\t \t \t Providing baseline adjusted traces. \n');
                    %script_log = [script_log, str];
                    %dispfun(str, config.verbose ==2);
                    
                    if config.l1_penalty_factor > ABS_TOL
                        % Penalize according to temporal overlap with neighbors
                        cor = get_comp_corr(S, T);
                        lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                            * config.l1_penalty_factor;
                    else
                        lambda = T(:, 1)' * 0;
                    end
                    
                    if config.adaptive_kappa > 0
                        try
                            [T, ~, ~, ~, ~] = solve_T_robust(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.frr_check_every_step, ...
                                config.plot_loss, config.trace_quantile, config.use_gpu, 0,@fp_solve_adaptive_baseline,4,config.kappa_iter_nums,config.frr_edge_case_flag);
                        catch
                                [T, ~, ~, ~, ~] = solve_T_robust(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.frr_check_every_step, ...
                                config.plot_loss, config.trace_quantile, config.use_gpu, 0,@fp_solve_adaptive_baseline,30,config.kappa_iter_nums,config.frr_edge_case_flag);   
                        end                         
                    else
                        try
                            [T, ~, ~, ~, ~] = solve_T_robust(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.frr_check_every_step, ...
                                config.plot_loss, config.trace_quantile, config.use_gpu, 0,@fp_solve_admm_baseline,4,[],config.frr_edge_case_flag);
                        catch
                            [T, ~, ~, ~, ~] = solve_T_robust(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.frr_check_every_step, ...
                                config.plot_loss, config.trace_quantile, config.use_gpu, 0,@fp_solve_admm_baseline,30,[],config.frr_edge_case_flag);
                        end
                    end

                    T = T - min(T,[],2);
                        
                case 'nonneg'
                    %str = sprintf('\t \t \t Providing non-negative traces. \n');
                    %script_log = [script_log, str];
                    %dispfun(str, config.verbose ==2);
                    if (config.max_iter == 0)
                        if config.l1_penalty_factor > ABS_TOL
                            % Penalize according to temporal overlap with neighbors
                            cor = get_comp_corr(S, T);
                            lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                                * config.l1_penalty_factor;
                        else
                            lambda = T(:, 1)' * 0;
                        end

                        if config.adaptive_kappa > 0
                            try
                                [T, loss, np_x, np_y, np_time] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.TOL_sub, ...
                                config.plot_loss, @fp_solve_adaptive, config.use_gpu, 0);
                            catch
                                [T, loss, np_x, np_y, np_time] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.TOL_sub, ...
                                config.plot_loss, @fp_solve_adaptive, config.use_gpu, 0,30);
                            end
                        else
                            try
                                [T, loss, np_x, np_y, np_time] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.TOL_sub, ...
                                config.plot_loss, @fp_solve_admm, config.use_gpu, 0);
                            catch
                                [T, loss, np_x, np_y, np_time] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                                kappa, config.max_iter_T_final, config.TOL_sub, ...
                                config.plot_loss, @fp_solve_admm, config.use_gpu, 0);
                            end    
                        end

                    end
                case 'nonnegative_least_squares'
                    if (config.max_iter == 0)
                        if config.l1_penalty_factor > ABS_TOL
                            % Penalize according to temporal overlap with neighbors
                            cor = get_comp_corr(S, T);
                            lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                                * config.l1_penalty_factor;
                        else
                            lambda = T(:, 1)' * 0;
                        end
                        try
                            [T, loss, np_x, np_y, np_time] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                            kappa * (100/config.kappa_std_ratio), config.max_iter_T_final, config.TOL_sub, ...
                            config.plot_loss, @fp_solve_admm, config.use_gpu, 0);
                        catch
                            [T, loss, np_x, np_y, np_time] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                            kappa * (100/config.kappa_std_ratio), config.max_iter_T_final, config.TOL_sub, ...
                            config.plot_loss, @fp_solve_admm, config.use_gpu, 0,30);
                        end

                    end
                case 'least_squares'
                    
                    if config.l1_penalty_factor > ABS_TOL
                        % Penalize according to temporal overlap with neighbors
                        cor = get_comp_corr(S, T);
                        lambda = max(cor, [], 1) .* sum(S_smooth, 1) ...
                            * config.l1_penalty_factor;
                    else
                        lambda = T(:, 1)' * 0;
                    end
                    try
                        [T, ~, ~, ~, ~] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                            kappa * (100/config.kappa_std_ratio), config.max_iter_T_final, config.TOL_sub, ...
                            config.plot_loss, @fp_solve, config.use_gpu, 0);
                    catch
                        [T, ~, ~, ~, ~] = solve_T(T, S, M_before_dst, fov_size, avg_radius, lambda, ...
                            kappa * (100/config.kappa_std_ratio), config.max_iter_T_final, config.TOL_sub, ...
                            config.plot_loss, @fp_solve, config.use_gpu, 0,30);
                    end
                    
            end

            % The older code is below
            %[T, ~, ~, ~, ~] = solve_T(T, S, M_before_dst, fov_size, avg_radius, Tt(1,:) * 0, ...
            %        kappa, config.max_iter_T, config.TOL_sub, ...
            %        config.plot_loss, fp_solve_func, config.use_gpu, 0);
            if config.smooth_T
                T = medfilt1(gather(T), 3, [], 2);
            end
        else
            T = Tt';
        end
    end
    % Interpolate bad traces
    if ~isempty(T_bad)
        T_bad_t = interp1(round(linspace(1, n_orig, n)), T_bad', 1:n_orig);
        T_bad = T_bad_t';
        clear T_bad_t;
    end
end


try
    % Divide temporal activity by mean fluorescence (for dF/F)
    S_prob = bsxfun(@rdivide, S, sum(S, 1));
    F_per_cell = S_prob' * config.F_per_pixel(:);
    T = bsxfun(@rdivide, T, F_per_cell);
    % Same for bad cells
    if ~isempty(T_bad)
        S_bad_prob = bsxfun(@rdivide, S_bad, sum(S_bad, 1));
        F_per_bad_cell = S_bad_prob' * config.F_per_pixel(:);
        T_bad = bsxfun(@rdivide, T_bad, F_per_bad_cell);
    end
catch
    if ~isempty(T)
        warning('Unknown error when normalizing traces')
    end
end

% Interpolate S if space was downsampled
if dss > 1
    [fov_y, fov_x, n] = size(M_before_dss);
    b0 = dss / 2 - 0.5;
    bxe = mod(fov_x, dss) + b0;
    bye = mod(fov_y, dss) + b0;
    [X, Y] = meshgrid(...
        round(linspace(1 + b0, fov_x - bxe, fov_size(2))),...
        round(linspace(1 + b0, fov_y - bye, fov_size(1))));
    [Xq, Yq] = meshgrid(1:fov_x, 1:fov_y);
    % Upsample summary_image & max_image
    summary_image = interp2(X, Y, summary_image, Xq, Yq, 'spline');
    max_image = interp2(X, Y, max_image, Xq, Yq, 'spline');
    config.F_per_pixel = interp2(X, Y, config.F_per_pixel , Xq, Yq, ...
                'spline');
    if ~isempty(S)
        num_components = size(S, 2);
        S_3d = reshape(S, fov_size(1), fov_size(2), num_components);
        S_3d_full = zeros(fov_y, fov_x, num_components, 'single');
        for k = 1:num_components
            S_3d_full(:,:,k) = interp2(X, Y, S_3d(:, :, k), Xq, Yq, ...
                'spline');
        end
        S = reshape(S_3d_full, fov_y * fov_x, num_components);
        S = normalize_to_one(S);
        % Update bad cell images too
        if ~isempty(S_bad)
            num_bad_components = size(S_bad, 2);
            S_bad_3d = reshape(S_bad, fov_size(1), fov_size(2), num_bad_components);
            S_bad_3d_full = zeros(fov_y, fov_x, num_bad_components, 'single');
            for k = 1:num_bad_components
                S_bad_3d_full(:,:,k) = interp2(X, Y, S_bad_3d(:, :, k), Xq, Yq, ...
                    'spline');
            end
            S_bad = reshape(S_bad_3d_full, fov_y * fov_x, num_bad_components);
            S_bad = normalize_to_one(S_bad);
        end
        clear S_3d_full S_bad_3d_full;
        % if asked to reconstruct full S, then re-estimate S for all pixels
        if config.reestimate_S_if_downsampled
            str = sprintf('\t \t \t Re-stimating S for all pixels... \n');
            script_log = [script_log, str];
            dispfun(str, config.verbose ==2);
            mask = make_mask(single(S > 0.4), [fov_y, fov_x], ...
                mask_extension_radius * dss);
            M_before_dss = reshape(M_before_dss, fov_y * fov_x, n);
            % Update kappa according to dss
            kappa = kappa * dss;
            [S, ~, ~, ~, ~] = solve_S(S, T, M_before_dss, mask, fov_size, avg_radius, ...
                S(1, :) * 0, kappa, config.max_iter_S, config.TOL_sub, ...
                config.plot_loss, @fp_solve_admm, config.use_gpu);
            S = normalize_to_one(S);
        end
    end
end

% If desired, save space by deleting non-essential data in summary
if config.compact_output
    S_bad = zeros(prod(fov_size), 0, 'single');
    T_bad = zeros(0, n, 'single');
    if isfield(init_summary, 'S_trash')
        init_summary = rmfield(init_summary, {'S_trash', 'T_trash'});
    end
end

if config.use_sparse_arrays
    % Make image arrays sparse
    S = sparse(double(S));
    S_bad = sparse(double(S_bad));
end
time_summary.frr = posixtime(datetime)-start_frr;


summary.S_bad = S_bad;
summary.T_bad = T_bad;
summary.S_loss = S_loss;
summary.T_loss = T_loss;
summary.T_change = T_change;
summary.S_change = S_change;
summary.init_summary = init_summary;
summary.log = script_log;
summary.classification = classification;
summary.summary_image = summary_image;
summary.max_image = max_image;
summary.config = config;
summary.time_summary = time_summary;


    %---
    % Internal functions
    %---

    function C = get_comp_corr(S, T)
    % Compute a correlation metric based on spatial+temporal weights
        nk = size(S, 2);
        S_z = zscore(S, 1, 1) / sqrt(size(S, 1));
        CS = S_z' * S_z - eye(nk, 'single');
        T_z = zscore(T, 1, 2) / sqrt(size(T, 2));
        CT = T_z * T_z' - eye(nk, 'single');
        C = CT .* (CS > 0.2);
    end

    function varargout = delete_rows(is_trash, varargin)
    % Delete given rows in each input in varargin
        for i = 1:length(varargin)
            out  = varargin{i};
            out(is_trash, :) = [];
            varargout{i} = out;
        end
    end

    function varargout = delete_columns(is_trash, varargin)
    % Delete given columns in each input in varargin
        for i = 1:length(varargin)
            out  = varargin{i};
            out(:, is_trash) = [];
            varargout{i} = out;
        end
    end  

    function plot_func(loss, is_T, iter_idx, num_comp)
    % Plot loss
        plot_idx = 1+ (~is_T);
        var_str = 'T';
        if ~is_T, var_str = 'S'; end
        subplot(2, 1, plot_idx)
        plot(loss(3:end));
        title(sprintf('%s loss, iter: %d, # of components: %d',...
            var_str, iter_idx, num_comp));
        drawnow;
    end
%     
%     function [X2,loss] = quadratic_solve(X, A, B, mask, lambda, kappa, nIter, ...
%                 tol, compute_loss, use_gpu, transpose_B)
%         % Solve for X using fixed point algorithm inside fast-ADMM routine
%         % This function is gpu-aware.
% 
% 
%         loss = zeros(1,nIter,'single');
%         I = eye(size(X,2),'single');
%         [loss, I, X, A, B, lambda, mask] = maybe_gpu(use_gpu, ...
%             loss, I, X, A, B, lambda, mask);
% 
%         if transpose_B
%             B = B';
%         end
% 
%         X2 =  B * pinv(A);
%         loss = [1];
% 
%         X2 = gather(X2);
%     end

end
