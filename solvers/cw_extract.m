function [S, T, summary] = cw_extract(M, config)
% Extracts cells one by one using one-sided Huber estimator

[h, w, n] = size(M);
use_gpu = config.use_gpu;

% Defaults
init_radius = 5;

avg_radius = config.avg_cell_radius;
max_spread = 2;
% imopen_radius = ceil(init_radius/config.init_cellsize_tol);
elim_size_thresh = config.cellfind_numpix_threshold;
avg_cell_area = pi * avg_radius ^ 2;
min_num_pixels = avg_cell_area *config.thresholds.size_lower_limit;
max_num_pixels = avg_cell_area * config.thresholds.size_upper_limit;
avg_yield_threshold = 0.1;
yield_averaging_window = round(1/avg_yield_threshold);

show_each_cell = 0;


%%%%
%%% TEMP CODE!!!
%%%%
% M = reshape(M, h * w, n);
% M = bsxfun(@minus, M, mean(M, 1));
% M = bsxfun(@minus, M, mean(M, 2));
% M = reshape(M, h, w, n);


% Reduce noise in movie with a spatial filter
switch config.cellfind_filter_type
    case 'butter'
        M = spatial_bandpass(M, avg_radius, inf, ...
            config.spatial_lowpass_cutoff, use_gpu, config.smoothing_ratio_x2y);
    case 'gauss'
        M = spatial_gauss_lowpass(M, avg_radius, use_gpu);
    case 'wiener'
        M = imwiener(M, use_gpu);
    case 'movavg'
        moving_rad=max(floor(config.moving_radius),2);
        X=ones(moving_rad,moving_rad,1)/(moving_rad^2); 
        M=convn(M,X,'same');
    case 'median'
        M= medfilt3(M);
    case 'none'
    otherwise
        error('Filter type not supported.');
end


if config.visualize_cellfinding
    
    str = sprintf('\t \t \t Using cell finding visualization tool...\n');
    dispfun(str, config.verbose ==2);
    
    max_im = max(M,[],3);


    trace_snr_all = [];
    mov_snr_all = [];
    
    subplot(121)
    if config.visualize_cellfinding_full_range
        imshow(max_im,[ ])
    else
        min_movie_show = quantile(M,config.visualize_cellfinding_min,3);
        min_movie_show = min(min_movie_show(:));

        max_movie_show = quantile(M,config.visualize_cellfinding_max,3);
        max_movie_show = max(max_movie_show(:));
        imshow(max_im,[min_movie_show max_movie_show ])
    end
    drawnow;
    subplot(222)
    histogram(trace_snr_all)
    xlabel('Trace snr')
    ylabel('Number of good cells')
    drawnow;
    subplot(224)
    histogram(mov_snr_all)
    xlabel('cellfind min snr')
    ylabel('Number of good cells')
    drawnow;
    
end

% Flatten for subsequent processing
M = reshape(M, h * w, n);

% More efficient to use M transposed (cheaper to index in space this way)
Mt = M';
noise_per_pixel = estimate_noise_std(Mt, 1, use_gpu);
% Apply movie mask to noise if it exists
if ~isempty(config.movie_mask)
    noise_per_pixel = noise_per_pixel(config.movie_mask(:));
end
noise_std = median(noise_per_pixel);


% Get a stack of 2 ims (max im + im of max idx) -- used to get seed pixels
summary_stack = get_summary_stack(Mt, [h, w], max_spread, []);
summary.summary_im = reshape(summary_stack(:, 1), h, w);

% Stop finding cells if signal maximum is below a certain value
% Bias func is the underestimating bias of mis-specified robust estimation under no
% non-negative contamination (actually upper bound on it)
bias_func = @(k)  2 * (normpdf(k) + k.*normcdf(k) - k)./normcdf(k);
noise_limit = noise_std * config.cellfind_min_snr + ...
    noise_std * bias_func(config.cellfind_kappa_std_ratio);

% Second threshold is based on how much dimmer is the current pixel 
% compared to most bright region in the FOV
im_summary = summary_stack(:, 1);
dim_limit = quantile(im_summary(:), 0.999) / ...
    config.high2low_brightness_ratio;

min_magnitude = max(noise_limit, dim_limit);

dispfun(sprintf(...
    '\t \t \t \t noise std: %.4f \n\t \t \t \t minimum magnitude: %.4f \n',...
    noise_std, min_magnitude), config.verbose==2);

max_steps = config.cellfind_max_steps;

% Set an absolute minimum for noise threshold based on theoretical max of
% gaussians
mu = norminv(1 - 1/n) * (1 - 0.577) + 0.577 * norminv(1 - 1/n / exp(1));
% Mu is the mean of gumbel, and gumbel is very concentrated
abs_noise_threshold = 0;%noise_std * mu * 1.2;
% Initialize variables
S = zeros(h * w, max_steps, 'single');
T = zeros(max_steps, n, 'single');
% quality check related arrays
metrics = zeros(max_steps, 4, 'single');
is_attr_bad = false(max_steps, 5);

S_trash = S;
T_trash = T;
S_change = [];
T_change = [];

is_good = false(1, max_steps);
init_stop_reason = 'max_iter';

% Create image template
s_proto = fspecial('gaussian', 1 + 2 * [init_radius, init_radius], ...
    init_radius / 2.5);
% Scale so that maximum is at 1
s_proto = s_proto / max(s_proto(:));
maxes = [];
vals_max = [];

kappa_s = config.cellfind_kappa_std_ratio;
% Adaptive kappa for t if asked
if config.adaptive_kappa
    kappa_t = @(d, k, v, alpha) kappa_of_epsilon(eps_func(d, k, v, alpha));
else
    kappa_t = kappa_s;
end

num_good_cells = 0;
for i = 1:max_steps
    % Select seed pixel for next init cell
    mod_im_summary = modify_summary_image(summary_stack(:, 1), h, w, ...
        min_magnitude, elim_size_thresh);
%     mod_im_summary = mod_im_summary .*Cn;
    [val_max, ind_max] = max(mod_im_summary(:));
    % Check min magnitude condition
    if val_max < min_magnitude %max(abs_noise_threshold, min_magnitude)
        init_stop_reason = 'min_magnitude';
        break;
    end

    % Initialize image
    [y_max, x_max] = ind2sub([h, w], ind_max);
    maxes = [maxes, gather([y_max; x_max])]; %#ok<*AGROW>
    if config.init_with_gaussian
        s_init = generate_images_from_centroids(h, w, s_proto, ...
                [y_max; x_max], init_radius);
    else
        s_init = generate_init_image(Mt, h, w, ind_max, 0.5, floor(avg_radius*1.5));
    end
    s_2d_init = reshape(s_init, h, w);
    s_2d_init = single(s_2d_init);
    s_2d_init = maybe_gpu(use_gpu, s_2d_init);

    
    if (config.visualize_cellfinding && i>1 && ~is_bad)
        
            subplot(121)
            plot_cells_overlay(reshape(gather(s),h,w),[0,1,0],[])
            drawnow;
        
    end

    % Robust cell finding
    [s, t, t_corr, s_corr, s_change, t_change] = ...
        alt_opt_single(Mt, s_2d_init, noise_std, max_num_pixels, use_gpu, kappa_t, kappa_s);

    S_change = [S_change; s_change];
    T_change = [T_change; t_change];

    % Check attributes
    % check image isn't too small
    cell_area = gather(get_cell_areas(s));
    metrics(i, 1) = cell_area;
    is_attr_bad(i, 1) = cell_area < min_num_pixels;
    % Check image isn't too big
    is_attr_bad(i, 2) = cell_area > max_num_pixels;
    % Check trace magnitude
    max_t = gather(max(t));
    metrics(i, 2) = max_t;
    is_attr_bad(i, 3) = max_t < max(abs_noise_threshold, min_magnitude);
    trace_snr = max(medfilt1(gather(t))) / estimate_noise_std(t) / sqrt(2);
    % Check trace snr
    metrics(i, 3) = trace_snr;
    is_attr_bad(i, 4) = trace_snr < config.thresholds.T_min_snr;
    is_this_duplicate = is_duplicate(t, T, s, S);
    metrics(i, 4) = is_this_duplicate;
    % Check trace isn't duplicate
    is_attr_bad(i, 5) = is_this_duplicate;
    % Check trace snr
    is_bad = any(is_attr_bad(i, :));
%     fprintf('%d, %d, %d, %d \n', is_good_spatial1, is_good_spatial2, is_good_temporal1, is_good_temporal2);
    if show_each_cell
        subplot(321);
        imagesc(reshape(s, h, w));colormap jet; axis image;
        title(sprintf('Step: %d, is_good: %d', i, ~is_bad));
        subplot(322);
        imagesc(reshape(summary_stack(:, 1), h, w));axis image; colormap jet;colorbar;
        subplot(323);
        mod_im_summary = modify_summary_image(summary_stack(:, 1), h, w, ...
            min_magnitude, elim_size_thresh);
        imagesc(mod_im_summary);axis image; colormap jet;colorbar;
        subplot(324);
%         mmax_im = sqrt(reshape(sum(Mt.^2, 1)'/size(M, 2), h, w));% clim:[0, (noise_std*2)]
        mmax_im = s_2d_init;
        imagesc(mmax_im);axis image; colormap jet;colorbar;
        subplot(3, 2, [5, 6]);
        plot(t);
        pause;
    end

    

    % Subtract s * t
    idx_s = find(s_corr > 0);
    idx_t = find(t_corr > 0);
    Mt(idx_t, idx_s) = Mt(idx_t, idx_s) - gather(1.0 * t_corr(idx_t)' * s_corr(idx_s)');

    summary_stack = get_summary_stack(...
        Mt, [h, w], max_spread, summary_stack, idx_s);
    
    if is_bad
        pix_idx_lookup = reshape(1:h*w, h, w);
        [y, x] = ind2sub([h, w], ind_max);
        y_range = max(1, y-max_spread):min(h, y+max_spread);
        x_range = max(1, x-max_spread):min(w, x+max_spread);
        pix_idx = pix_idx_lookup(y_range, x_range);
        pix_idx = pix_idx(:);
        Mt(:, pix_idx) = Mt(:, pix_idx) * 0;
        summary_stack(pix_idx, 1) = summary_stack(pix_idx, 1) * 0;
        T_trash(i, :) = gather(t);
        S_trash(:, i) = gather(s);
    else
        num_good_cells = num_good_cells + 1;
        is_good(i) = true;
        vals_max = [vals_max, val_max];
        T(i, :) = gather(t);
        S(:, i) = gather(s);
        if config.visualize_cellfinding

            trace_snr_all = [trace_snr_all, gather(trace_snr)];
            mov_snr_all = [mov_snr_all, gather(max_t/noise_std - bias_func(config.cellfind_kappa_std_ratio))];

            subplot(121)
            plot_cells_overlay(reshape(gather(s),h,w),[1,0,0],[])
            title(['Cell finding in process. ' num2str(i) ' iterations ' num2str(num_good_cells) ' found.'])
            drawnow;
            subplot(222)
            histogram(trace_snr_all,ceil(i/10))
            xlabel('Trace snr')
            drawnow;
            subplot(224)
            histogram(mov_snr_all,ceil(i/10))
            xlabel('cellfind min snr')
            drawnow;
    
        end
    end
    
    % Stopping criterion based on the running yield of cells
    n = yield_averaging_window;
    avg_yield = mean(is_good(max(1, i-n+1):i));
    if i > 2 * n && avg_yield <= avg_yield_threshold
        init_stop_reason = 'yield';
        break;
    end
    
    if mod(i, 100)==0
        dispfun(sprintf('\t\t\t Step #%d, found %d cells... \n', ...
            i, num_good_cells), config.verbose == 2);
    end
end

if config.visualize_cellfinding
    subplot(121)
    title(['Cell finding completed. ' num2str(i) ' iterations ' num2str(num_good_cells) ' found.'])
    drawnow;
end

% Organize S & T matrices
S = S(:, is_good);
T = T(is_good, :);
S_trash = S_trash(:, ~is_good);
T_trash = T_trash(~is_good, :);

metrics = metrics(1:i, :);
is_attr_bad = is_attr_bad(1:i, :);
summary.metrics = metrics;
summary.is_attr_bad = is_attr_bad;
is_good = is_good(1:i);
summary.is_good = is_good;
summary.max_locations = maxes;
summary.max_values = vals_max;
summary.S_trash = S_trash;
summary.T_trash = T_trash;
summary.init_stop_reason = init_stop_reason;
summary.S_change = S_change;
summary.T_change = T_change;
summary.noise_per_pixel = noise_per_pixel;

dispfun(sprintf(...
    '\t \t \t %d cells found after a total of %d steps. \n', ...
    size(S, 2), i), config.verbose ==2);

%----
% Helper functions
%----
    

    function m2 = modify_summary_image(m, h, w, t, elim_size_thresh)
    % Get an adjusted summary image
        m = reshape(m, h, w);
        % Eliminate small valued pixels
        m2 = m .* (m > t);
        % Opening with a disk of a cell radius eliminates small peaks
        if elim_size_thresh > 0
            mo = bwareaopen(m2>0, elim_size_thresh);
            m2 = m2 .* (mo > 0);
        end
    end
%     function m2 = modify_summary_image(m, h, w, t, imopen_radius)
%     % Get an adjusted summary image
%         m = reshape(m, h, w);
%         % Eliminate small valued pixels
%         m2 = m .* (m > t);
%         % Opening with a disk of a cell radius eliminates small peaks
%         if isfinite(imopen_radius)
%             mo = imopen(uint8(m2/max(m2(:))*255), ...
%                 strel('disk', imopen_radius));
%             m2 = m2 .* (mo > 0);
%         end
%     end
    
    function is_it = is_duplicate(t, T, s, S)
        corr_thresh = 0.7;
        idx_valid = find(s>0);
        s = s(idx_valid);
        S = S(idx_valid, :);
        prox = s' * S / sum(s.^2);
        idx_look = find(prox > 0.1);
        is_it = 0;
        if ~isempty(idx_look)
            num_frames = length(t);
            T_prox = T(idx_look, :);
            tz = zscore(t, 0) / sqrt(num_frames);
            Tz = zscore(T_prox, 0, 2) / sqrt(num_frames);
            if any(tz * Tz' > corr_thresh)
                is_it = 1;
            end
        end
    end

end
