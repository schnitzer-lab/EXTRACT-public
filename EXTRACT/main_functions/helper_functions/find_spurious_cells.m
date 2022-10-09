function [corr_score, scores_1, scores_2, scores_3] = ...
        find_spurious_cells(S, T, M, S_surround, pre_T_in, pre_T_out, fov_size, avg_radius, use_gpu, visualize)
    
    S_MASK_THRESHOLD = 0.01;
    T_MASK_THRESHOLD = 0.5;
    GAUSS_FILTER_RADIUS_SMALL = avg_radius;
    GAUSS_FILTER_RADIUS_LARGE = avg_radius * 2;
    
    % Re-compute if S & T variants if not given
    if isempty(S_surround) || isempty(pre_T_in) || isempty(pre_T_out)
        
        % Get mask for cell images
        Mask = S > S_MASK_THRESHOLD;

        [m, n] = size(M);
        if use_gpu
            GPU_SLACK_FACTOR = 3;
            d = gpuDevice();
            avail_size = d.AvailableMemory / 4 / GPU_SLACK_FACTOR;
            num_chunks = ceil(m * n / avail_size);
        else
            num_chunks = 1;
        end
        % Compute S_corr & S_surround
        pre_S_corr = S * 0;
        T_noise_limit = sqrt(2)*3*get_trace_noise(T);
        T_zm = max(0, bsxfun(@minus, T, T_noise_limit));
        T_zm = maybe_gpu(use_gpu, T_zm);
        for i = 1:num_chunks
            indices = select_indices(n, num_chunks, i);
            M_small = maybe_gpu(use_gpu, M(:, indices));
            pre_S_corr = pre_S_corr + gather(M_small * T_zm(:, indices)');
            clear M_small;
        end
        clear T_zm;

        % Process S_corr
        S_smooth = smooth_images(S, fov_size, GAUSS_FILTER_RADIUS_SMALL, use_gpu);
        S_smooth = normalize_to_one(S_smooth);
        Mask_surround = S_smooth > S_MASK_THRESHOLD;
        Mask_surround = single(Mask_surround);
        S_corr = pre_S_corr .* Mask_surround;

        % Get image correlation score
        S_corr_norm = bsxfun(@rdivide, S_corr, sqrt(sum(S_corr.^2, 1)));
        S_norm = bsxfun(@rdivide, S, sqrt(sum(S.^2, 1)));
        corr_score = gather(sum(S_corr_norm .* S_norm, 1));

        % Process S_surround
        S_smooth = smooth_images(S, fov_size, GAUSS_FILTER_RADIUS_LARGE, use_gpu);
        S_smooth = normalize_to_one(S_smooth);
        Mask_surround = S_smooth > S_MASK_THRESHOLD;
        Mask_surround = single(Mask_surround);
        S_surround = pre_S_corr .* Mask_surround;
        S_surround(S_surround <0) = 0;
        S_surround(Mask > 0) = 0;
        S_surround = normalize_to_one(S_surround);

        pre_T_in = T;
        pre_T_out = T;
        % Compute T variants
        for i = 1:num_chunks
            indices = select_indices(n, num_chunks, i);
            M_small = maybe_gpu(use_gpu, M(:, indices));
            % Project movie onto within-cell and out-of-cell regions
            pre_T_in(:, indices) = gather(maybe_gpu(use_gpu, S)' * M_small);
            pre_T_out(:, indices) = gather(maybe_gpu(use_gpu, S_surround)' * M_small);
            clear M_small;
        end
    
    else
        % Bypass corr_score
        corr_score = ones(1, size(T, 1), 'single');  
    end
    
    
    norms_S = sqrt(sum(S.^2, 1))';
    maxes_S = max(S, [], 1)';
    S_scale = maxes_S ./ norms_S;
    norms_S_surround =sqrt(sum(S_surround.^2, 1))';
    maxes_S_surround = max(S_surround, [], 1)';
    S_surround_scale = maxes_S_surround ./ norms_S_surround;
    T_in_fluo = max(bsxfun(@rdivide, pre_T_in, norms_S),0);
    T_out_fluo = max(bsxfun(@rdivide, pre_T_out, norms_S_surround),0);
    T_in_scaled = max(bsxfun(@times, T_in_fluo, S_scale), 0);
    T_out_scaled = max(bsxfun(@times, T_out_fluo, S_surround_scale), 0);
    
    % Compute residuals from projections
    R1 = max(T_in_scaled - T, 0);  % Activity in ROI not explained by cell
    R2 = max(T - T_out_scaled,0);  % Marginal activity in the cell, explained by trace
    R3 = max(0,T_in_fluo - T_out_fluo);  % Marginal activity in the cell

    %Mask for temporal activities > threshold
    t_max = max(T, [], 2);
    T_mask = bsxfun(@minus, T, t_max * T_MASK_THRESHOLD) > 0;
    
    % Per event metrics:
    % Compute scores based on different quantiles for the 3 metrics
    p = 1;
    quantiles = [0.01, 0.25, 0.5, 0.75, 0.99];
    scores_1 = zeros(length(quantiles), size(T, 1), 'single');
    scores_2 = zeros(length(quantiles), size(T, 1), 'single');
    scores_3 = zeros(length(quantiles), size(T, 1), 'single');
    for i = 1:size(T, 1)
        r1 = R1(i, :);
        r2 = R2(i, :);
        r3 = R3(i, :);
        t = gather(T(i, :));
        t_mask = gather(T_mask(i, :));
        t_in_fluo = gather(T_in_fluo(i, :));
        [active_frames, num_active_frames] = get_active_frames(t_mask>0, 0);
        s1 = [];
        s2 = [];
        s3 = [];
        for j = 1:num_active_frames
            frames_this = active_frames(j, 1):active_frames(j, 2);
            normalizer_scaled = sum(t(frames_this).^p);
            normalizer_fluo = sum(t_in_fluo(frames_this).^p);
            s1 = [s1, (sum(r1(frames_this).^p) / normalizer_scaled).^(1/p)]; %#ok<*AGROW>
            s2 = [s2, (sum(r2(frames_this).^p) / normalizer_scaled).^(1/p)];
            s3 = [s3, (sum(r3(frames_this).^p) / normalizer_fluo).^(1/p)];
        end
        for k = 1:length(quantiles)
            scores_1(k, i) = quantile(s1, quantiles(k));
            scores_2(k, i) = quantile(s2, quantiles(k));
            scores_3(k, i) = quantile(s3, quantiles(k));
        end
    end
    
    if exist('visualize','var') && visualize
        for i = 1:size(S, 2)
            s = reshape(S(:,i), fov_size(1), fov_size(2));
            s_sur = reshape(S_surround(:, i), fov_size(1), fov_size(2));
            imsum = s+s_sur;
            imsum = imsum/max(imsum(:));
            save('save','pre_S_corr','pre_T_in','pre_T_out');
            x_range = find(sum(imsum,1) > 0);
            x_range = x_range(1):x_range(end); % make sure of continuity
            y_range = find(sum(imsum,2) > 0);
            y_range = y_range(1):y_range(end);
            subplot(2,2,1)
            imagesc(s(y_range, x_range));axis image off;colormap jet;
            title(i);
            subplot(2,2,2)
            imagesc(s_sur(y_range, x_range));axis image off;colormap jet;
            subplot(2,2,[3,4])
            plot(T(i,:));
            hold on;
            plot(T_out_scaled(i,:));
            hold off;
            title(sprintf('metric: %.3f', scores_2(3,i)));
            pause;
        end
    end
end