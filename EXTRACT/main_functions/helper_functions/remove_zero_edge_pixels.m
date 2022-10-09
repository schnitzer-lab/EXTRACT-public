function [M, nz_top, nz_bottom, nz_left, nz_right] = remove_zero_edge_pixels(M)
% Find near-zero stripes at edges, typically caused by motion registration.
    ABS_TOL = 1e-6;
    [h,w,~] = size(M);
    absM = abs(M);
    x_section = squeeze(mean(absM, 1));
    y_section = squeeze(mean(absM, 2));
    clear absM;
    
    [idx_last_bad_low, idx_first_bad_high] = get_bad_edge_indices(x_section, w);
    nz_left = idx_last_bad_low;
    nz_right = w - idx_first_bad_high +1;

    [idx_last_bad_low, idx_first_bad_high] = get_bad_edge_indices(y_section, h);
    nz_top = idx_last_bad_low;
    nz_bottom = h - idx_first_bad_high + 1;

    % Remove zero edges
    M = M(nz_top+1:end-nz_bottom, nz_left+1:end-nz_right, :);
    
    
    function [idx_last_bad_low, idx_first_bad_high] = ...
            get_bad_edge_indices(section, dim_size)
        % Detect spikes in the profile
        mins = min(section, [], 2);
%         diffs = abs(diff(mins, 1));
%         diffs = [0; diffs]; % ensure same size as mins
%         median_diff = median(diffs);
%         value_threshold = 10 * median_diff;
%         is_problem = diffs > value_threshold;
        is_problem = mins < median(mins) - 10*std(mins);
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
            % Include the pixel before for consistency (was indirectly done
            % for low index)
            idx_first_bad_high = idx_first_bad_high - 1;
        end
    end
    
end