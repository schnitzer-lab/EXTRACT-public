function [idx_k_good, idx_k_bad] = guess_labels_from_metrics(metrics)

    k = 5;
    bad_limit = 0.3;
    good_limit = 0.7;
    % Guess good or bad cells from normalized spatiotemporal metrics.
    [f_map, ~] = get_quality_metric_map;

    idx_st2 = f_map('ST2_index_3');
    idx_st3 = f_map('ST3_index_3');
    idx_st_corr_2 = f_map('ST_corr_2');
    idx_st_corr_3 = f_map('ST_corr_3');
%     guess_good = find((metrics(idx_st2, :) > 0.8 & metrics(idx_st3, :) > 0.8) ...
%         | metrics(idx_st_corr_2, :) > 0.6);
%     guess_bad = find((metrics(idx_st2, :) < 1e-2 | metrics(idx_st3, :) < 1e-2) ...
%         | metrics(idx_st_corr_3, :) < (0.3)); 
    
    metric_for_bad = metrics(idx_st_corr_3, :);
    metric_for_good = metrics(idx_st_corr_3, :);
    % Choose k examples from each
    [~,  idx_k_bad] = mink(metric_for_bad, k);
    [~, idx_k_good] = maxk(metric_for_good, k);
    
    % Make sure they're within acceptable hard limits
    idx_k_bad(metric_for_bad(idx_k_bad) > bad_limit) = [];
    idx_k_good(metric_for_good(idx_k_good) < good_limit) = [];
    
    % Have at least 1 example from each class
    if isempty(idx_k_bad)
        [~, idx_k_bad] = min(metric_for_bad);
    end
    if isempty(idx_k_good)
        [~, idx_k_good] = max(metric_for_good);
    end
end