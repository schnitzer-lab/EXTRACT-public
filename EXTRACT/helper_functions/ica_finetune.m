function [indep, mixing] = ica_finetune(M, num_comp)
% Find a demixing matrix W such that M*W = independent components
% Steps:
% 1. get SVD of M: M = USV'
% 2. ICA on U: U * ica_W = independent
% 3. Obtain ica mixing: M = (U*ica_A) * (ica_A'*S*V') => mixing = ica_W'*S*V'
% Result: M = independent * mixing

    term_tol = 1e-5;
    max_iter = 750;
    
    
    [U, Sigma, V] = svd(M, 'econ');
    ica_A = compute_ica_weights(U', num_comp, term_tol, max_iter);
    ica_W = ica_A';
    indep = U * ica_A;
    mixing = ica_W * Sigma * V';
    
    % post-process output
%     h = fov_size(1);
%     w = fov_size(2);
%     for i = 1:size(indep,2)
%         s = indep(:, i);
%         s(s<max(s)*0.2) = 0;
%         CC = bwconncomp(reshape(s, h, w)>0);
%         lengths = cellfun(@length, CC.PixelIdxList);
%         [~, idx_max_length] = max(lengths);
%         s_new = zeros(h*w, 1, 'single');
%         s_new(CC.PixelIdxList{idx_max_length}) = s(CC.PixelIdxList{idx_max_length});
%         s_new = s_new/max(s_new);
%         indep(:, i) = s_new;
%     end
end

