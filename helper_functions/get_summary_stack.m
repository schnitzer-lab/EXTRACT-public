function summary_stack = get_summary_stack(Mt, fov_size, ex, summary_stack, idx_diff)
    % Get a summary image from the transposed movie.
    % Summary image corresponds to a modified max image with enhanced SNR
    % Values correspond to mean over frames where neighbors are max
    height = fov_size(1);
    width = fov_size(2);
    n = size(Mt, 1);
    pix_idx_lookup = reshape(1:height*width, height, width);

    if ~exist('idx_diff', 'var')  % make a brand new summary_stack
        idx_affected = 1:(height*width);
        summary_stack = zeros(height*width, 4, 'single');
        [~, t_max] = max(Mt, [], 1);
        summary_stack(:, 2) = t_max';
    else  % Update existing summary_stack
        is_diff = zeros(height*width, 1, 'single');
        is_diff(idx_diff) = 1;
        idx_affected = find(imfilter(reshape(is_diff, height, width), ones(2*ex+1)))';
        [~, t_max_sub] = max(Mt(:, idx_diff), [], 1);
        % Update t_max for pixels that were altered
        summary_stack(idx_diff, 2) = t_max_sub;
    end

    for idx = idx_affected
        [y, x] = ind2sub(fov_size, idx);
        y_range = max(1, y-ex):min(height, y+ex);
        x_range = max(1, x-ex):min(width, x+ex);
        pix_idx = pix_idx_lookup(y_range, x_range);
        pix_idx = pix_idx(:);
        % Exclude the current pixel
        pix_idx(find(pix_idx==idx, 1)) = [];
        ts = summary_stack(pix_idx, 2);
%         summary_stack(idx, 1) = mean(Mt(ts, idx));
        t_max_this = summary_stack(idx, 2);
        summary_stack(idx, 1) = mean(Mt(t_max_this, pix_idx));
    end

end