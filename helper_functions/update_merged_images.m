function [S, T] = update_merged_images(S, T, S_smooth, merge)
    
%     T_fuzzy =  corr(S_smooth(:, merge.idx_merged)) * T(merge.idx_merged, :);
    for i = 1:length(merge.idx_merged)
        c = sqrt(sum(T(merge.cc(i).indices, :).^2, 2));
        S(:, merge.idx_merged(i)) = S(:, merge.cc(i).indices)*c;
    end
    S = normalize_to_one(S);
end