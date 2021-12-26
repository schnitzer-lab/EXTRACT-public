function M = fix_zero_spatial_strips(M)
% Fix near-zero stripes at edges, typically caused by motion registration.
% Function iteratively replaces the zero slices with the values of the 
% neighboring slices.

    [h,w,~] = size(M);
    
    % Fix vertical stripes (indexed by x)
    x_section = squeeze(mean(abs(M), 1));
    diff_x_section = diff(x_section, 1, 1);
    % Pad with zero from the left for size consistency
    diff_x_section = padarray(diff_x_section, 1, 0, 'pre');
    [idx_last_bad_low, idx_first_bad_high, value_threshold] = get_bad_edge_indices(diff_x_section, w);

    % Fix beginning idx
    idx_low = idx_last_bad_low:-1:1;
    for i = idx_low
        is_problem_t = abs(diff_x_section(i,:)) > value_threshold;
        M(:, i, is_problem_t) = M(:, i+1, is_problem_t);
    end
    % Fix ending idx
    idx_high = idx_first_bad_high:w;
    for i = idx_high
        is_problem_t = abs(diff_x_section(i,:)) > value_threshold;
        M(:, i, is_problem_t) = M(:, i-1, is_problem_t);
    end
    
    % Fix horizontal stripes (indexed by y)
    y_section = squeeze(mean(abs(M), 2));
    diff_y_section = diff(y_section, 1, 1);
    % Pad with zero from the left for size consistency
    diff_y_section = padarray(diff_y_section, 1, 0, 'pre');
    [idx_last_bad_low, idx_first_bad_high, value_threshold] = get_bad_edge_indices(diff_y_section, h);
    % Fix beginning idx
    idx_low = idx_last_bad_low:-1:1;
    for i = idx_low
        is_problem_t = abs(diff_y_section(i,:)) > value_threshold;
        M(i, :, is_problem_t) = M(i+1, :, is_problem_t);
    end
    % Fix ending idx
    idx_high = idx_first_bad_high:h;
    for i = idx_high
        is_problem_t = abs(diff_y_section(i,:)) > value_threshold;
        M(i, :, is_problem_t) = M(i-1, :, is_problem_t);
    end

    function [idx_last_bad_low, idx_first_bad_high, value_threshold] = ...
            get_bad_edge_indices(diff_section, dim_size)
        % Detect spikes
        value_threshold = 10 * std(diff_section(:));
        is_problem = any(abs(diff_section) > value_threshold, 2);
        idx_middle = round(dim_size/2);
        idx_last_bad_low = find(is_problem(1:idx_middle), 1, 'last');
        if isempty(idx_last_bad_low)
            idx_last_bad_low = 0;
        end
        idx_first_bad_high = find(is_problem(idx_middle:end), 1, 'first');
        if isempty(idx_first_bad_high)
            idx_first_bad_high = dim_size + 1;
        else
            idx_first_bad_high = idx_first_bad_high + idx_middle - 1;
        end
    end
    
end