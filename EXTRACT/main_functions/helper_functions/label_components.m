function [label_good, label_bad, idx_elim] = ...
        label_components(metrics, thresholds, S_smooth, T_smooth)
% Manual labeling per hard-coded thresholds
    % Almost zero traces
    is_T_zeroed = (metrics(1, :) < thresholds.T_elim_thresh);
    % Bad looking traces
    is_T_poor_looking = metrics(2, :) > thresholds.temporal_corrupt_thresh;
    % Tiny images
    is_S_tiny = (metrics(4, :) <= thresholds.size_lower_limit) |...
        (metrics(5, :)<= thresholds.size_lower_limit);
    % Too large images
    is_S_huge = (metrics(6, :) >= thresholds.size_upper_limit);% | (metrics(7, :) >= thresholds.size_upper_limit);
    % Poor looking images
    is_S_poor_looking = (metrics(9, :) > thresholds.spat_corrupt_thresh);
    % Images with high eccentricity (blood vessels, dendrites etc.)
    is_S_poor_eccent = (metrics(10, :) > thresholds.eccent_thresh);
    % Bad spatio-temporal activity
    is_ST_spurious = metrics(18, :) < thresholds.low_ST_index_thresh | ...
        metrics(23, :) < thresholds.low_ST_index_thresh;
    % Duplicate traces
    if ~isempty(T_smooth)
        is_T_duplicate = find_excess_components(T_smooth',...
            thresholds.T_dup_corr_thresh); 
    else
        is_T_duplicate = false;
    end
    % Duplicate images
    if ~isempty(S_smooth)
        is_S_duplicate = find_excess_components(S_smooth, thresholds.S_dup_corr_thresh);
    else
        is_S_duplicate = false;
    end
    % Remove bad components
    is_elim = is_T_zeroed | is_T_poor_looking | is_S_tiny | ...
        is_S_huge |  is_S_poor_looking | is_S_poor_eccent ...
        | is_ST_spurious;
    num_components_this_iter = length(is_S_duplicate);
    is_elim(1:num_components_this_iter) = ...
        is_elim(1:num_components_this_iter) | is_S_duplicate | is_T_duplicate;
    idx_elim = find(is_elim);
    label_bad = find(is_ST_spurious);

    % Good spatio-temporal activity
    is_ST_good = metrics(18, :) > thresholds.high_ST_index_thresh & ...
        metrics(23, :) > thresholds.high_ST_index_thresh;
    label_good = find(is_ST_good);
end