function plot_bad_cells(output, idx_partition, idx_iter)
    if nargin < 3 || isempty(idx_iter)
        idx_iter = length(output.info.summary(idx_partition).classification);
    end
    [h, w, ~] = size(output.spatial_weights);
    is_attr_bad = output.info.summary(idx_partition).classification(idx_iter).is_attr_bad;
    metrics = output.info.summary(idx_partition).classification(idx_iter).metrics;
    num_good_cells = size(output.info.summary(idx_partition).T_change, 1);
    % Exclude good cell indices from metrics and is_attr_bad
    metrics = metrics(:, num_good_cells+1:end);
    is_attr_bad = is_attr_bad(:, num_good_cells+1:end);
    spat_corruptions = metrics(9, :);
    trace_snrs = metrics(1, :);
    is_s_bad = is_attr_bad(7, :);
    sum(is_s_bad)
    is_t_bad = is_attr_bad(3, :);
    S_bad_small = output.info.summary(idx_partition).S_bad;
    S_bad = zeros(h*w, size(S_bad_small, 2));
    S_bad(output.info.summary(idx_partition).fov_occupation(:), :) = S_bad_small;
    ims_bad = reshape(S_bad, h, w, size(S_bad, 2));
    T_bad = output.info.summary(idx_partition).T_bad;
    ex = 5;  % number of zero pixels around image boundary for plotting
    for i = 1:size(S_bad, 2)
        im = ims_bad(:, :, i);
        if sum(im(:)) > 0
            [x_range, y_range] = get_image_xy_ranges(im, ex);
            im_small = im(y_range(1):y_range(2), x_range(1):x_range(2));
            subplot(1,4,1);
            imagesc(im_small); axis image; colormap jet;
            title(sprintf('spat corr: %.2f, is-s-bad: %d', spat_corruptions(i), is_s_bad(i)));
            subplot(1,4, [2,3,4]);
            plot(T_bad(i, :));
            title(sprintf('trace snr: %.1f, is-t-bad: %d', trace_snrs(i), is_t_bad(i)));
            pause;
        end
    end