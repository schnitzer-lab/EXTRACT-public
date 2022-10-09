function idx_trash = find_duplicate_cells(S, Tt, overlap_idx,T_dup_thresh,T_corr_thresh,S_corr_thresh)
    
    if nargin < 4
        T_dup_thresh = 0.9;
    end
    if nargin < 5
        T_corr_thresh = 0.8;
    end
    if nargin < 6
        S_corr_thresh = 0.1;
    end
    
    % Select only cells in the overlap regions
    images_in_overlap = S(overlap_idx, :);
    idx_select = find(sum(images_in_overlap, 1) > 0);
    
    % Find spatially overlapping group of cells
    cc_image = find_conncomp(S(:, idx_select), S_corr_thresh);
    
    idx_trash = [];
    
    % For each group of overlapping cells, check if duplicates exist
    for k = 1:length(cc_image)
        idx_with_spat_overlap = idx_select(cc_image(k).indices);

        % 1st Pass: cells with very high trace correlation
        cc_trace = find_conncomp(Tt(:, idx_with_spat_overlap),...
            T_dup_thresh);
        idx_trash_this = [];
        for kk = 1:length(cc_trace)
            idx_duplicate = idx_with_spat_overlap(cc_trace(kk).indices);
            S_sub = double(S(:, idx_duplicate) > 0);
            areas = sum(S_sub, 1);
            [~, idx_largest] = max(areas);
            % Eliminate all but the largest cell
            idx_duplicate(idx_largest) = [];
            idx_trash_this = [idx_trash_this, idx_duplicate];
        end
        idx_trash = [idx_trash, idx_trash_this];  %#ok<*AGROW>
        % Remove the eliminated cell indices from idx_with_spat_overlap
        idx_with_spat_overlap = setdiff(idx_with_spat_overlap, ...
                idx_trash_this);

        % 2nd pass: recursively eliminate the most "connected" cell
        [cc_trace, C] = find_conncomp(Tt(:, idx_with_spat_overlap),...
            T_corr_thresh);
        for kk = 1:length(cc_trace)
            idx = cc_trace(kk).indices;
            idx_duplicate = [];
            while length(idx) > 2
                Cs = C(idx, idx) - eye(length(idx));
                if max(Cs, [], 1) < T_corr_thresh
                    break;
                end
                [~, idx_discard] = max(sum(Cs, 1));
                idx_discard = idx(idx_discard);
                idx = setdiff(idx, idx_discard);
                idx_duplicate = [idx_duplicate, ...
                    idx_with_spat_overlap(idx_discard)];
            end
            % If there are only two cells left, keep the one
            % with stronger trace
            if length(idx) == 2
                T_goodness = max(Tt(:,idx_with_spat_overlap(idx)), [], 1);
                [~, idx_discard] = min(T_goodness);
                idx_discard = idx(idx_discard);
                idx_duplicate = [idx_duplicate, ...
                    idx_with_spat_overlap(idx_discard)];
            end
            idx_trash = [idx_trash, idx_duplicate]; 
        end
    end
end