function [T_corr_in, T_corr_out, S_surround,S_smooth] = get_pre_correlations(S, T, M, avg_radius)
    
    [nx,ny,nt] = size(M);
    
    X = mean(M,3);
    M=(M-X)./X;

    fov_size=[nx,ny];
    S_smooth = smooth_images(S, fov_size,...
        round(avg_radius / 2), 0, true);
    S_smooth = normalize_to_one(S_smooth);

    mask = make_mask(single(S_smooth > 0.1),fov_size, round(avg_radius ));

    
    M = reshape(M,nx*ny,nt);
    Mt = M';
    clear M;

    
    CPU_SPACE_SIDELEN = 10 * 2 * avg_radius; % ~10 cells wide
    % Work with transposed T variants for better indexing
    Tt_corr_in = zeros(fliplr(size(T)), 'single');
    Tt_corr_out = zeros(fliplr(size(T)), 'single');
    S_out = zeros(size(S), 'single');
    S_surround = zeros(size(S), 'single');
    
    [nt, ns] = size(Mt);
    h = fov_size(1);
    w = fov_size(2);
    
    % Subtract trace noise from traces to avoid potential side-effects
    T_noise_limit = sqrt(2)*3*estimate_noise_std(T);
    T = max(0, bsxfun(@minus, T, T_noise_limit));

    % Decide on space partitions
    % CPU partitions
    np_x = max(round(w / CPU_SPACE_SIDELEN), 1);
    np_y =np_x;

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
            S_in_sub = S(idx_space, :);
            mask_in_sub = mask(idx_space, :);
            idx_comp = find(sum(mask_in_sub, 1)>0);
            if ~isempty(idx_comp)  % Proceed only if non-empty partition
                % sub-matrices
                S_in_sub = S_in_sub(:, idx_comp);
                mask_sub = mask(idx_space, idx_comp);
                T_sub = T(idx_comp, :);
                Mt_sub = Mt(:, idx_space);
                S_out_sub = S_in_sub;
                S_out(idx_space, idx_comp) = S_out_sub;
                
                
                
                % Update S_surround & T_corr_in & T_corr_out

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