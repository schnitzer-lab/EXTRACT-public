function metric = temporal_corruption(T)
% Compute a temporal badness metric from cell traces
    T_med = medfilt1(T, 3, [], 2);
    T_diff = abs(T - T_med);
    X = T_diff ./ (max(T_med, T));
    threshold = max(T_med, [], 2) * 0.3;
    is_valid = bsxfun(@minus, T_med, threshold) > 0;
    metric = zeros(1, size(T, 1), 'single');
    for i = 1:size(T, 1)
        x = X(i, is_valid(i, :));
        metric(i)  = mean(x);
    end

end