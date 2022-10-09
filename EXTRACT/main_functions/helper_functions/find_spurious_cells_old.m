function [scores_1, scores_2] = find_spurious_cells_old(S, T, M, fov_size, use_gpu)
    
    S_MASK_THRESHOLD = 0.001;
    T_MASK_THRESHOLD = 0.5;
    GAUSS_FILTER_RADIUS = 2;
    [S, T] = maybe_gpu(use_gpu, S, T);

    % Get masks for cell images
    Mask = S > S_MASK_THRESHOLD;
    % Get masks & images for rings around cells
    S_smooth = smooth_images(S, fov_size, GAUSS_FILTER_RADIUS);
    S_smooth = normalize_to_one(S_smooth);
    Mask_surround = S_smooth > S_MASK_THRESHOLD;
    Mask_surround(Mask > 0) = 0;
    Mask_surround = single(Mask_surround);
    S_surround = (M * T') .* Mask_surround;
    S_surround(S_surround <0) = 0;
    S_surround = normalize_to_one(S_surround);

    T1 = T;
    T2 = T;
    if use_gpu
        [m, n] = size(M);
        GPU_SLACK_FACTOR = 2;
        d = gpuDevice();
        avail_size = d.AvailableMemory / 4 / GPU_SLACK_FACTOR;
        num_chunks = ceil(m * n / avail_size);
    else
        num_chunks = 1;
    end
    for i = 1:num_chunks
        indices = select_indices(m, num_chunks, i);
        M_small = gpuArray(M(:, indices));
        % Project movie activity on components of S separately:
        T1(:, indices) = S' * M_small;
        % Project movie activity on components of S_surround separately:
        T2(:, indices) = S_surround' * M_small;
    end
    % Scalings
    T1 = bsxfun(@rdivide, T1, sum(S.^2, 1)');
    T2 = bsxfun(@rdivide, T2, sum(S_surround.^2, 1)');
    
    
    % Compute residuals from both projections
    R1 = T1 - T;
    R2 = min(T2 - T,0);
%     R2 = T2 - T;
    %Mask for temporal activities > threshold
    t_max = max(T, [], 2);
    T_mask = bsxfun(@minus, T, t_max * T_MASK_THRESHOLD) > 0;

    % Compute scores based on ratio of the two residuals after masking
    normalizer = sum(T .* T_mask, 2);
    scores_1 = bsxfun(@rdivide, sum(R1 .* T_mask, 2), normalizer)';
    scores_2 = bsxfun(@rdivide, sum(R2 .* T_mask, 2), normalizer)';
%     scores = scores_1 ./ scores_2;
    scores_1 = gather(scores_1);
    scores_2 = gather(scores_2);

end