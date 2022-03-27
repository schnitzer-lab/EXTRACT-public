function [S_out, l, np_x, np_y, T_corr_in, T_corr_out, S_surround] = solve_S(...
        S_in, T, Mt, mask, fov_size, avg_radius, ...
        lambda, kappa, max_iter, TOL, compute_loss, est_func, use_gpu)
    
    GPU_SLACK_FACTOR = 20;
    CPU_SPACE_SIDELEN = 10 * 2 * avg_radius; % ~10 cells wide
    % Work with transposed T variants for better indexing
    Tt_corr_in = zeros(fliplr(size(T)), 'single');
    Tt_corr_out = zeros(fliplr(size(T)), 'single');
    S_out = zeros(size(S_in), 'single');
    S_surround = zeros(size(S_in), 'single');
    [nt, ns] = size(Mt);
    h = fov_size(1); w = fov_size(2);
    l = {};  % If asked, keep loss in a cell array
    % Subtract trace noise from traces to avoid potential side-effects
    T_noise_limit = sqrt(2)*3*estimate_noise_std(T);
    T = max(0, bsxfun(@minus, T, T_noise_limit));
    % Decide on space partitions
    % CPU partitions
    np_x = max(round(w / CPU_SPACE_SIDELEN), 1);
    np_y =np_x;
    % GPU partitions (forced to be >= CPU partitions)
    if use_gpu
        d = gpuDevice();
        avail_size = d.AvailableMemory / 4; % 32 bit precision
        sp_space = avail_size / GPU_SLACK_FACTOR / nt;
        np_x = max(round(sqrt(ns / sp_space)), 1);
        np_y = ceil(ns / sp_space / np_x);
    end

    % Get nonzero idx of S - only these will be estimated
    idx_S_nonzero = find(sum(mask, 2) > 0);
    % Solve for S in multiple sub-problems
    for i_x = 1:np_x
        idx_x = select_indices(w, np_x, i_x);
        for i_y = 1:np_y
            idx_y = select_indices(h, np_y, i_y);
            % convert space indices from 2d to 1d
            [sub_x, sub_y] = meshgrid(idx_x, idx_y);
            idx_space = sort(sub2ind(fov_size, sub_y(:), sub_x(:)));
            idx_space = intersect(idx_space, idx_S_nonzero);
            S_in_sub = S_in(idx_space, :);
            mask_in_sub = mask(idx_space, :);
            idx_comp = find(sum(mask_in_sub, 1)>0);
            if ~isempty(idx_comp)  % Proceed only if non-empty partition
                % sub-matrices
                S_in_sub = S_in_sub(:, idx_comp);
                mask_sub = mask(idx_space, idx_comp);
                T_sub = T(idx_comp, :);
                Mt_sub = Mt(:, idx_space);
                % Solve regression
                [S_out_sub, l{end+1}] = est_func(S_in_sub, T_sub, Mt_sub, ...
                    mask_sub, lambda(idx_comp), kappa, max_iter, TOL, ...
                    compute_loss, use_gpu, 1);
                S_out(idx_space, idx_comp) = S_out_sub;
                % Update S_surround & T_corr_in & T_corr_out
                [Mt_sub, S_out_sub, T_sub] = maybe_gpu(...
                    use_gpu, Mt_sub, S_out_sub, T_sub);
                S_surround_sub = max(0, (T_sub * Mt_sub)');
                S_surround_sub(S_out_sub > 0.01) = 0;
                S_surround_sub(~mask_sub) = 0;
                S_surround(idx_space, idx_comp) = gather(S_surround_sub);

                Tt_corr_in(:, idx_comp) = Tt_corr_in(:, idx_comp) + ...
                    gather((Mt_sub * S_out_sub));
                Tt_corr_out(:, idx_comp) = Tt_corr_out(:, idx_comp)  + ...
                    gather((Mt_sub * S_surround_sub));
                clear Mt_sub S_out_sub S_surround_sub T_sub;
            end
        end
    end
    T_corr_in = Tt_corr_in';
    T_corr_out = Tt_corr_out';
    % Ensure correct scaling of images
    [S_out, scale_s] = normalize_to_one(S_out);
    T_corr_in = bsxfun(@times, T_corr_in, scale_s');
end