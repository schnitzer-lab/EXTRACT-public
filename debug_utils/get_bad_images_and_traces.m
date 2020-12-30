function [ims, traces, is_attr_bad, metrics] = get_bad_images_and_traces(output)
    num_partitions = length(output.info.summary);
    [h, w, ~] = size(output.spatial_weights);
    n = size(output.temporal_weights, 1);
    ims = zeros(h, w, 0);
    traces = zeros(0, n);
    is_attr_bad = zeros(9, 0);
    [f_map, ~] = get_quality_metric_map;
    n_metrics = length(f_map);
    metrics = zeros(n_metrics, 0);
    for i_part = 1:num_partitions
        % Exclude good cell indices from is_attr_bad
        num_good_cells = size(output.info.summary(i_part).S_change, 1);
        is_attr_bad_this = output.info.summary(i_part).classification(end).is_attr_bad;
        metrics_this= output.info.summary(i_part).classification(end).metrics;
%         is_attr_bad_this(:, 1:num_good_cells) = [];
        traces_this = output.info.summary(i_part).T_bad;
        S_bad_small = output.info.summary(i_part).S_bad;
        S_bad = zeros(h*w, size(S_bad_small, 2));
        S_bad(output.info.summary(i_part).fov_occupation(:), :) = S_bad_small;
        ims_this = reshape(S_bad, h, w, size(S_bad, 2));
        
        traces = cat(1, traces, traces_this);
        ims = cat(3, ims, ims_this);
        is_attr_bad = cat(2, is_attr_bad, is_attr_bad_this);
        metrics = cat(2, metrics, metrics_this);
    end
end