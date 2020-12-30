function x = solve_single_source(a,B,kappa,N,lambda)
% Newton solve loss(a*x_i - b_i) for i in dim(x), b_i=ith column of B.
% loss() is one-sided huber.

TOL = 1e-4;
k = size(B, 2);
A = repmat(a, 1, k); % repeat in the 2nd dimension
A_sq = repmat((a .^ 2) / kappa, 1, k);
AB = A .* B / kappa;
% Initialize x to the least quares solution
x = sum(AB, 1) / sum(A_sq(:, 1));

% Iteratively approach to optiumum
for i = 1:N
    x_before = x;
    mask = (B-a * x) > kappa;
    mask_not = ~mask;
    mask = single(mask);
    mask_not = single(mask_not);
    x = (sum(AB .* mask_not, 1) + sum(A .* mask, 1) -lambda) ./ ...
        sum(A_sq .* mask_not, 1);
    x = max(x, 0);
    if sum(abs(x - x_before)) / sum(x_before) < TOL
        break;
    end
end

end
