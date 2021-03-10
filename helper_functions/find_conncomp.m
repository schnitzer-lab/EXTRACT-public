function [cc, A] = find_conncomp(X, threshold, A2)
% Finds connected components of columns of A wrt a corr. threshold
% A2 (optional) is an additional adjacency matrix as a multiplicative constraint

    tiny = 1e-6;
    XpX = full(X'*X);
    mean_X = full(mean(X, 1));
    XpX_norm = XpX - size(X, 1)*(mean_X'*mean_X);
    norms_X = sqrt(diag(XpX_norm)') + tiny;
    C = XpX_norm ./ (norms_X'*norms_X);
    A = gather(C > threshold);

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
