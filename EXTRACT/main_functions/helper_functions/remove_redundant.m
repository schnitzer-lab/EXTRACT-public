function [x, is_bad] = remove_redundant(...
        x, S, S_smooth, T, M, pre_S_corr, pre_T_corr_in, pre_T_corr_out, fov_size, avg_radius, use_gpu, thresholds,sparse_arrays)
    num_cells_this_iter = size(T, 1);
    [fmap, ~] = get_quality_metric_map;
    
    % Populate metrics
    metrics = zeros(length(fmap), num_cells_this_iter);
    % T metrics:
    metrics(fmap('T_maxval'), :) = get_trace_snr(T);
    metrics(fmap('T_corruption'), :) = temporal_corruption(T);
    T_smooth = medfilt1(T, 3, [], 2);
    T_norm = zscore(T_smooth, 1, 2) / sqrt(size(T_smooth, 2));
    metrics(fmap('T_max_corr'), :) = max(T_norm * T_norm', [], 1);
    % S metrics:
    metrics(fmap('S_area_1'), :) = get_cell_areas(S, 0.2);
    metrics(fmap('S_smooth_area_1'), :) = get_cell_areas(S_smooth, 0.2);
    metrics(fmap('S_area_2'), :) = get_cell_areas(S);
    metrics(fmap('S_smooth_area_2'), :) = get_cell_areas(S_smooth);
    S_norm = zscore(S_smooth, 1, 1) / sqrt(size(S_smooth, 1));
    metrics(fmap('S_max_corr'), :) = max(S_norm' * S_norm, [], 1);
    metrics(fmap('S_corruption'), :) = spat_corruption(S, fov_size,[],sparse_arrays);
    [circularities, eccentricities] = get_circularity_metrics(S, fov_size);
    metrics(fmap('S_circularity'), :) = circularities;
    metrics(fmap('S_eccent'), :) = eccentricities;
    % Spatio-temporal metrics:
    idx_ST_123 = [fmap('ST1_index_1'), fmap('ST1_index_2'),...
        fmap('ST1_index_3'), fmap('ST1_index_4'), fmap('ST1_index_5'), ...
        fmap('ST2_index_1'), fmap('ST2_index_2'), fmap('ST2_index_3'), ...
        fmap('ST2_index_4'), fmap('ST2_index_5'), fmap('ST3_index_1'), ...
        fmap('ST3_index_2'), fmap('ST3_index_3'), fmap('ST3_index_4'), ...
        fmap('ST3_index_5')];
    if thresholds.low_ST_index_thresh == -1
        metrics(idx_ST_123, :) =1;
        metrics([fmap('ST_corr_1'), fmap('ST_corr_2'), fmap('ST_corr_3')], :) = 1;
    else
        [~, metrics(idx_ST_123(1:5), :), ...
            metrics(idx_ST_123(6:10), :), ...
            metrics(idx_ST_123(11:15), :),] = ...
            find_spurious_cells(S, T, M, pre_S_corr, pre_T_corr_in, ...
            pre_T_corr_out, fov_size, avg_radius, use_gpu);
        metrics([fmap('ST_corr_1'), fmap('ST_corr_2'), fmap('ST_corr_3')], :) = ...
            get_st_corr_metrics(M, S, T, fov_size, avg_radius);
    end
    % Set NaN metrics to zero
    metrics(isnan(metrics(:))) = 0;
    
    % Get high-confidance labels based on hard-coded thresholds on metrics
    [idx_elim, is_attr_bad, merge] = get_bad_components(metrics, ...
        thresholds, S, T, S_smooth);
    
    % If not the first iteration, update metrics & attr labels using previous
    % bad cells
    if ~isempty(x)
        metrics = [metrics, x(end).metrics(:, x(end).is_bad)];
        is_attr_bad = [is_attr_bad, x(end).is_attr_bad(:, x(end).is_bad)];
    end
    num_cells_all = size(metrics, 2);

    % Get bad cells
    is_bad = false(1, num_cells_this_iter);
    is_bad(idx_elim) = true;
    is_bad = is_bad(1:num_cells_this_iter);

%     % Bad cell images & traces
%     S_bad = S(:, is_bad);
%     T_bad = T(is_bad, :);
% 
%     % If not the first iteration then include mc from eliminated cells
%     if ~isempty(x)
%         S_bad = [S_bad, x(end).S_bad];
%         T_bad = [T_bad; x(end).T_bad];
%     end
    
    % Obtain updated EXTRACT scores for all cells
    [guess_good, guess_bad] = guess_labels_from_metrics(metrics);
    guessed_labels = zeros(num_cells_all, 1);
    guessed_labels(guess_good) = 1;
    guessed_labels(guess_bad) = -1;
%     [scores, ~] = ml_predict_labels(metrics', guessed_labels, true);
    
    % Make classification struct for this iter
    x(end+1).metrics = metrics;
    x(end).is_attr_bad = is_attr_bad;
    x(end).is_bad = is_bad;
%     x(end).S_bad = S_bad;
%     x(end).T_bad = T_bad;
    x(end).merge = merge;
%     x(end).scores = scores;
    
    % Re-order all current & previous matrices according to current
    % good / bad classification (only for cells in this iter)
    for ii = length(x):-1:1
        x(ii).metrics(:, 1:num_cells_this_iter) = ...
            [x(ii).metrics(:, ~is_bad), x(ii).metrics(:, is_bad)];
        x(ii).is_attr_bad(:, 1:num_cells_this_iter) = ...
            [x(ii).is_attr_bad(:, ~is_bad), x(ii).is_attr_bad(:, is_bad)];
    end
    % Update x(end).is_bad
    num_good_cells = sum(~is_bad);
    x(end).is_bad = [false(1, num_good_cells), ...
        true(1, num_cells_all-num_good_cells)];
    
    %-------------------
    % Internal Functions
    %-------------------
    
    function [idx_elim, is_attr_bad, merge] = ...
            get_bad_components(metrics, thresholds, S, T, S_smooth)
    % Manual labeling per hard-coded thresholds
        % Almost zero traces
        is_T_zeroed = (metrics(fmap('T_maxval'), :) <= thresholds.T_min_snr);
        % Bad looking traces
        is_T_poor_looking = metrics(fmap('T_corruption'), :) >= ...
            thresholds.temporal_corrupt_thresh;
        % Tiny images
        is_S_tiny = (max(metrics(fmap('S_area_1'), :), metrics(fmap('S_smooth_area_1'), :)) <= thresholds.size_lower_limit) |...
            (metrics(fmap('S_smooth_area_1'), :) == 0);
        % Too large images
        is_S_huge = ((metrics(fmap('S_area_2'), :) ./ ...
            max(1,-2+metrics(fmap('S_eccent'), :))) >= thresholds.size_upper_limit);
        % Poor looking images
        is_S_poor_looking = (metrics(fmap('S_corruption'), :) >= thresholds.spatial_corrupt_thresh);
        % Images with high eccentricity (blood vessels, dendrites etc.)
        is_S_poor_eccent = (metrics(fmap('S_eccent'), :) >= thresholds.eccent_thresh);
        % Bad spatio-temporal activity
        is_ST_spurious = metrics(fmap('ST2_index_3'), :) <= thresholds.low_ST_index_thresh | ...
            metrics(fmap('ST2_index_3'), :) <= thresholds.low_ST_index_thresh | ...
            metrics(fmap('ST_corr_3'), :) < thresholds.low_ST_corr_thresh;
        % Duplicate traces
        if ~isempty(T)
            % Enforce spatial proximity through an overlap adjacency matrix
            A = single(S > 0.05);
            A = (A' * A) > 0;
            [merge, is_T_duplicate] = find_excess_components(T'*corr(S_smooth),... %*(S'*S_smooth)
                thresholds.T_dup_corr_thresh, A); 
        else
            is_T_duplicate = false;
            merge = [];
        end
        % Duplicate images
        if ~isempty(S)
            [~, is_S_duplicate] = find_excess_components(S_smooth, thresholds.S_dup_corr_thresh);
        else
            is_S_duplicate = false;
        end
        
        % Consolidate all attributes
        is_attr_bad = [is_T_duplicate; is_S_duplicate; is_T_zeroed ; is_T_poor_looking ; is_S_tiny ; ...
            is_S_huge ;  is_S_poor_looking ; is_S_poor_eccent ...
            ; is_ST_spurious];
        % Determine bad components
        is_elim = any(is_attr_bad, 1);
        % Merged cells stay:
        is_elim(merge.idx_merged) = false;
        
        num_components_this_iter = length(is_S_duplicate);
        is_elim(1:num_components_this_iter) = ...
            is_elim(1:num_components_this_iter);
        idx_elim = find(is_elim);
    end
    
    function [merge, is_excess] = find_excess_components(M, corr_threshold, A2)
    % Find extraneous columns by computing connected components and
    % removing the one with most neighbors for each connected graph
    % A2 is an optional adjacency matrix used as multiplciative constraint
        if exist('A2', 'var')
            C = find_conncomp(M, corr_threshold, A2);
        else
            C = find_conncomp(M, corr_threshold);
        end
        is_excess = false(1, size(M,2));
        Conn = zeros(size(M, 2), 'single');
        idx_merged = zeros(1, length(C), 'single');
        for i = 1:length(C)
            % Place an edge between every connected component
            Conn(C(i).indices, C(i).indices) = 1;
            idx_merged(i) =  C(i).indices(1);
            is_excess(C(i).indices(2:end)) = true;
        end
        % Remove the diagonal from Conn
        Conn = Conn - eye(size(Conn), 'single');
        if ~isempty(C)
            merge.Conn = Conn;
            merge.idx_merged = idx_merged;
            merge.cc = C;
        else
            merge.idx_merged = [];
        end
    end
    
end