function [M_out, scale] = normalize_to_one(M)
% Normalize each column in M to have max of 1
    scale = max(1e-6, max(M, [], 1));
    M_out = bsxfun(@rdivide, M, scale);
end