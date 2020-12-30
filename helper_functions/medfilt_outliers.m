function [M, num_outliers] = medfilt_outliers(M)
% Median filtering for only pixels that exhibit different activities than
% their neighbors
% M: input 3-D movie matrix
% returns M: output movie with outlying pixels replaced by 
% median of its immediate neighbors
    % Deviation threshold, normalized to (0, 1)
    deviation_threshold = 0.5;
    [h, w, t] = size(M);
    % Identify bad pixels
    max_image = max(M, [], 3);
    m_med = medfilt2(max_image, [5, 5]);
    rat = max_image ./ m_med;
    idx_bad = find(rat < 1 - deviation_threshold | ...
        rat > 1 + deviation_threshold);
    [y_bad, x_bad] = ind2sub([h, w], idx_bad);
    num_outliers = length(y_bad);
    % Manual replacement by median of neighbors
    for i = 1:num_outliers 
        x_neighbors = max(min(x_bad(i) + (-1:1), w), 1);
        y_neighbors = max(min(y_bad(i) + (-1:1), h), 1);
        M_neighbors = reshape(M(y_neighbors, x_neighbors, :),...
            length(x_neighbors) * length(y_neighbors), t);
        M(y_bad(i), x_bad(i), :) = median(M_neighbors, 1);
    end
end