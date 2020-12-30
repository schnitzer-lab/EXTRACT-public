function [cc, A] = find_conncomp(X, threshold, A2)    
% Finds connected components of columns of A wrt a corr. threshold
% A2 (optional) is an additional adjacency matrix as a multiplicative constraint

    mean_X = mean(X, 1);
    X_norm = bsxfun(@minus, X, mean_X);
    norms_X = sqrt(sum(X_norm.^2, 1));
    X_norm = bsxfun(@rdivide, X_norm, norms_X + 1e-6);
    A = gather((X_norm' * X_norm) > threshold);
    if exist('A2', 'var')
        A = A .* A2;
    end
    [s, memberships] = graphconncomp(sparse(A)); 
    cc = [];
    acc=0;
    for k = 1:s
        idx = find(memberships == k);
        if numel(idx) > 1
            % Find idx with most common neighbors
            [~, i] = max(sum(A(:, idx), 1));
            acc = acc + 1;
            % idx with most common neighbors goes last
            cc(acc).indices = [idx(setdiff(1:length(idx), i)), idx(i)];
        end
    end       
    
end
