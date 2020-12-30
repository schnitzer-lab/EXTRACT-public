function M = correct_baseline(M, tau, remove_background, use_gpu)
% Removes baseline offset in 2-D or 3-D movie with following steps:
%    - sample baseline for overlapping small segments
%    - smooth baseline samples
%    - interpolate samples to 1:length(trace) to get the time varying
%      baseline estimate
%    - subtract baseline estimate from the trace
% This function takes non-gpuArray M, and returns a non-gpuArray M.
    ABS_TOL = 1e-6;
    is_3d = ndims(M) == 3;
    if is_3d
        [h, w, n] = size(M);
        m = h * w;
        M = reshape(M, h * w, n);
    else
        [m, n] = size(M);
    end
    
    if use_gpu
        GPU_SLACK_FACTOR = 4;
        d = gpuDevice();
        avail_size = d.AvailableMemory / 4 / GPU_SLACK_FACTOR;
        num_chunks = ceil(m * n / avail_size);
    else
        num_chunks = 1;
    end
    
    % Compute the power in each pixel (used for computing static
    % background)
    ppp = std(M, 0, 2);
    for i = 1:num_chunks
        indices = select_indices(m, num_chunks, i);
        if remove_background
            ppp_this = ppp(indices);
        else
            ppp_this = [];
        end
        if any(ppp_this > 0)
            M(indices, :) = remove_baseline_func(...
                M(indices, :), tau, ppp_this,  use_gpu);
        end
    end
    if is_3d
        M = reshape(M, h, w, n);
    end


    function M = remove_baseline_func(M, tau, ppp, use_gpu)
        [num_components, num_frames] = size(M);
        k = round(tau * 50);  % Sampling period
        ss = round(k * 2);  % Sample size
        smoothing_hlen = 5;%  Half-length of the baseline smoothing filter
        
        M = maybe_gpu(use_gpu, M);
        
        % Remove static background 
        if ~isempty(ppp)
            s = ppp;
            for ik = 1:1
                t = s' * M / max(1e-6, sum(s.^2));
                s = max(M * t' / sum(t.^2), 0);
                t = maybe_gpu(use_gpu, medfilt1(gather(t)));
            end
            M = M - s * t;
        end
        % Make sure the movie is zero-mean in time
        means = mean(M, 2);
        M = bsxfun(@minus, M, means);
        
        % Compute a step size for quantization (used for histogram)
        stds = std(M, 1, 2);
        stds = stds(stds > ABS_TOL);
        stat = median(stds);
        step_size = stat / 5;
        edges = (-10 * stat):step_size:(10 * stat);

        % Sample baseline at uniformly spaced points    
        num_samples = max(3, ceil(num_frames / k)); % At least 3 samples
        sampled_indices = round(linspace(1, num_frames, num_samples));
        baselines = zeros(num_components, num_samples, 'single');
        baselines = maybe_gpu(use_gpu, baselines);

        for idx_sample = 1:num_samples
            idx_begin = max(1, sampled_indices(idx_sample) - round(ss / 2));
            idx_end = min(num_frames, ...
                sampled_indices(idx_sample) + round(ss / 2));
            data = M(:, idx_begin:idx_end);

            % Baseline estimate is the most frequent bin in the histogram
            hist_counts = histc(data, edges, 2);

    %         hist_counts = maybe_gpu(use_gpu, ...
    %             zeros(num_components, length(edges)-1, 'single'));
    %         for idx_pixel = 1:num_components
    %             [hist_counts(idx_pixel, :), ~] = histcounts(...
    %                 data(idx_pixel, :), edges);
    %         end

            % indices with most frequent values
            [~, idx_max] = max(hist_counts, [], 2);

            %most frequent values
            most_freq_vals = edges(idx_max)' + step_size / 2;

            baselines(:,idx_sample) = most_freq_vals;
        end
        clear data;

        % Smooth the baseline values with moving average filter
        filt_out = zeros(num_components, num_samples, 'single');
        filt_out = maybe_gpu(use_gpu, filt_out);
        % Manual convolution (to avoid edge effects)
        for idx_sample = 0:num_samples - 1
            idx_begin = max(1, 1 + idx_sample - smoothing_hlen);
            idx_end = min(num_samples, idx_sample + smoothing_hlen + 1);
            b = baselines(:, idx_begin:idx_end);
            filt_out(:, idx_sample + 1) = (mean(b, 2));
        end
        
        % Transfer to CPU (suspected GPU over-use when interpolation is on GPU)
        filt_out = gather(filt_out);

        % Interpolate the sample baseline points
        % Matlab accepts the array to be interpolated as column vectors
        subt = interp1(sampled_indices, ...
            filt_out', (1:num_frames)', 'linear')';
        subt = maybe_gpu(use_gpu, subt);
%         std_subt = std(subt, 0, 2);
%         fprintf('\t\t\t 70 percentile baseline std: %.4f \n', quantile(std_subt, 0.7));
        M = M - subt;
        mean_M = mean(M, 2);
        M = bsxfun(@minus, M, mean_M);
        M = gather(M);
    end
end