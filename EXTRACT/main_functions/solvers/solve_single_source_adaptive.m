function x = solve_single_source_adaptive(a, B, max_iter, lambda, noise_std, kappa_func)
% Newton solve loss(a*x_i - b_i) for i in dim(x), b_i=ith column of B.
% Kappa is estimated from the residuals.
% loss() is one-sided Huber.

use_gpu = isa(B, 'gpuArray');

TOL = 1e-4;
k = size(B, 2);
a2 = a.^2;

% Initialize x to the NNLS solution
x = max(0, (a'*B)/ sum(a2));

% Initialize kappa
kappa = ones(1, k, 'single');
kappa = maybe_gpu(use_gpu, kappa);

% If kappa is a function, do adaptive kappa
is_adaptive = ~isnumeric(kappa_func);
if is_adaptive
    idx_estimate_kappa = round(max_iter*[1/2, 2/3, 3/4]);
    % a_mask is computed for computing avg. data statistic for kappa est
    a_mask = (1./(1+1*a)) .* (a>0);
    a_mask = (a_mask)'/sum(a_mask);
    % alpha is a variable needed for kappa est
    alpha = 0.05*sum(a)/sum(a>0)*mean(a)/mean(a.^2);
else
    idx_estimate_kappa = [];
    % kappa_func is the user-defined numeric kappa value
    kappa = kappa * kappa_func;
end

scaled_kappa = kappa * noise_std;


% Newton solve
i = 0;
while i < max_iter
    i = i + 1;
    x_before = x;
    res = B-a * x;

    % Estimate kappa
    if ismember(i, idx_estimate_kappa)
        v = 0;
        % Compute the data statistics
        d_proto = (bsxfun(@minus, res, v*noise_std)>0);
        d = a_mask * d_proto;
        % Update kappa
        kappa = maybe_gpu(use_gpu, kappa_func(d, kappa, v, alpha));
        % Update kappa*noise_std
        scaled_kappa = kappa * noise_std;
    end
    
    mask = bsxfun(@ge, res, scaled_kappa);
    clear res;
    mask_not = ~mask;

    x = a'*(B.*mask_not);
    x = x + scaled_kappa.*(a'*single(mask) -lambda);
    x = x ./ (a2'* single(mask_not));
    x = max(x, 0);
    
    % Convergence criterion
    if  sum(abs(x - x_before)) / sum(x_before) < TOL
        % Set i to either to the next kappa estimation index, or N
        control_array = [idx_estimate_kappa, max_iter];
        i = control_array(find(control_array > i, 1)) - 1;
        % Terminate if all kappa estimation steps are done
        if i == max_iter - 1
            break;
        end
    end
end

end
