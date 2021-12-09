function [T_out, l, np_x, np_y, np_time] = solve_T(T_in, S, M, fov_size, avg_radius, lambda, ...
        kappa, max_iter, TOL, compute_loss, est_func, use_gpu, is_M_transposed)
    
    GPU_SLACK_FACTOR = 4;
    CPU_SPACE_SIDELEN = 10 * 2 * avg_radius; % ~10 cells wide
    T_out = zeros(size(T_in), 'single');
    % For T-step, M must be passed to regression in transposed form
    if is_M_transposed
        [nt, ns] = size(M);
        transpose_M = false;
    else
        [ns, nt] = size(M);
        transpose_M = true;
    end
    h = fov_size(1); w = fov_size(2);
    l = {};  % If asked, keep loss in a cell array
    % Decide on space & time partitions
    if use_gpu
        d = gpuDevice();
        avail_size = d.AvailableMemory / 4; % 32 bit precision
        sp = sqrt(avail_size / GPU_SLACK_FACTOR);
        np_x = max(round(sqrt(ns / sp)), 1);
        np_y = max(ceil(sqrt(ns / sp)), 1);
        np_time = ceil(nt / sp);
    else
        np_x = max(round(w / CPU_SPACE_SIDELEN), 1);
        np_y = max(round(h / CPU_SPACE_SIDELEN), 1);
        np_time = 1;
    end

    % Get nonzero idx of S - only these will be used for T estimation
    idx_S_nonzero = find(sum(S, 2) > 0);
    % Solve for T in multiple sub-problems
    for i_x = 1:np_x
        idx_x = select_indices(w, np_x, i_x);
        for i_y = 1:np_y
            idx_y = select_indices(h, np_y, i_y);
            % convert space indices from 2d to 1d
            [sub_x, sub_y] = meshgrid(idx_x, idx_y);
            idx_space = sort(sub2ind(fov_size, sub_y(:), sub_x(:)));
            idx_space = intersect(idx_space, idx_S_nonzero);
            S_sub = S(idx_space, :);
            idx_comp = find(sum(S_sub, 1)>0);
            if ~isempty(idx_comp)  % Proceed only if non-empty partition
                S_sub = S_sub(:,idx_comp);
                power_s_sub = sum(S_sub.^2, 1)';
                for i_t = 1:np_time
                    idx_t = select_indices(nt, np_time, i_t);
                    if is_M_transposed
                        M_sub = M(idx_t, idx_space);
                    else
                        M_sub = M(idx_space, idx_t);
                    end
                    T_in_sub = T_in(idx_comp, idx_t);
                    % Solve regression
                    [Tt_out_sub, l{end+1}] = est_func(T_in_sub', S_sub', M_sub, ...
                        [], lambda(idx_comp), kappa, max_iter, TOL, ...
                        compute_loss, use_gpu, transpose_M);
                    % Weight T components by their image powers
                    T_out(idx_comp, idx_t) = T_out(idx_comp, idx_t) + ...
                        bsxfun(@times, Tt_out_sub', power_s_sub);
                end
            end
        end
    end
    % Divide each T component by total power of its image
    power_s = sum(S.^2, 1)';
    T_out = bsxfun(@rdivide, T_out, power_s);
end