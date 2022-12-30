function [X2,loss] = fp_solve_adaptive_filter(X, A, B, mask, lambda, noise_std,...
        nIter, tol, compute_loss, use_gpu, transpose_B)
% Solve for X using fixed point algorithm inside ADMM routine
% This function is gpu-aware.


RHO_UPDATE_FREQ = inf;
EPS_REL = 1e-3;
EPS_ABS = 1e-6;

% Params for adaptive rho
eta = 3;
mu = 1.2;

nIter_sub = 1;
opt_2 = 0;

loss = zeros(1,nIter,'single');
I = eye(size(X,2),'single');
[loss, I, X, A, B, lambda, mask] = maybe_gpu(use_gpu, ...
    loss, I, X, A, B, lambda, mask);

if transpose_B
    B = B';
end

% Scale covariates for better conditioning
scale = max(sqrt(sum(A.^2, 2)), 1e-8);
A = bsxfun(@rdivide, A, scale);
X = bsxfun(@times, X, scale');
lambda = lambda ./ scale';

Ac = A * A';
e = eig(Ac);
lambda_min = e(1);
lambda_max = e(end);
% Compute acceptable upper limit on condition number. This is based on
% the expected condition number of a random gaussian square matrix,
% which is theta(n) (n is # dimensions).
cond_limit_upper = size(Ac, 1) / 3;
lambda_min = max(lambda_min, lambda_max / cond_limit_upper);
rho = sqrt(lambda_min * lambda_max);
iAc = (Ac + rho * I) \ I;
pA = A' * iAc;
decay = lambda * iAc * 0; % Used to be * kappa
X_ls = B * pA;

X2 = X;
Y = X * 0;
n = numel(X);  % Problem dimension

% Initialize kappa
kappa =0.6361*noise_std * ones(size(B), 'single');
kappa = maybe_gpu(use_gpu, kappa);
pre_kappa = maybe_gpu(use_gpu, 0.6361*ones(size(A,2), size(A, 1), 'single'));

% Estimate kappa at below iteration indices
idx_estimate_kappa = round(nIter*[0.5, 0.7, 0.9]);

k = 0;
acc = 0;
while k < nIter
    k = k + 1;
    acc = acc + 1;
    % Estimate kappa
    if ismember(k, idx_estimate_kappa)
        clear kappa;
        v = 0;
        res = B - X * A;
        res_temp = res';
        % Update estimate of noise_std
        noise_std = std(res_temp, 0, 2);
        noise_std = median(noise_std);
%         fprintf('noise std estimate:%.4f\n', noise_std);
        % Compute the data statistics
        A_maxes = max(X2', [], 2);
        A_unscaled = bsxfun(@rdivide, X2', A_maxes);
        A_mask = ( (1./ (1+0*A_unscaled)) .* (A_unscaled > 0.01) )';
        A_mask = bsxfun(@rdivide, (A_mask), sum(A_mask, 1));
        res_temp = single(res_temp > v*noise_std);
        res_temp = res_temp * A_mask;

        pre_eps = eps_func(res_temp, pre_kappa, v, 0.05);
        pre_eps = medfilt1(gather(pre_eps), 5, [], 1);

        A_weighting = bsxfun(@rdivide, A_unscaled+1e-6, sum(A_unscaled+1e-6, 1));
        eps = pre_eps * gather(A_weighting);
        kappa = maybe_gpu(use_gpu, noise_std * kappa_of_epsilon(eps));
        pre_kappa = kappa_of_epsilon(pre_eps);
        kappa = kappa';
        clear res_temp pre_eps;
    end
    % X fixed-point update
    for i = 1:nIter_sub
        res = X * A - B;
        res = min(res + kappa, 0);
        X = res * pA + X_ls;
        clear res;
        if ~opt_2
        X = bsxfun(@minus, X, decay);
        end
        X = X + (-Y + X2) * iAc * rho; 
    end
    % X2 update
    X2_m1 = X2;
    X2 = max(bsxfun(@minus, X + Y, opt_2 * lambda / rho), 0);
    if ~isempty(mask)
        X2 = X2 .* mask;
    end
    % Dual update
    Y = Y + X - X2;
    % Compute loss
    if compute_loss
        if use_gpu
            f = arrayfun(@f_loss_gpu, X2 * A - B, kappa);
        else
            f = f_loss_cpu(X2 * A - B, kappa);
        end
        f = sum(f(:));
        penalty_term = bsxfun(@times, X2, lambda);
        f = f + sum(penalty_term(:));
        loss(acc)=f;
    end
    % Primal and dual residuals
    r = X - X2;
    d = rho * (X2 - X2_m1);
    % Rho update
    if mod(k,RHO_UPDATE_FREQ) == 0
        ratio = norm(r(:)) / norm(d(:));
        if ratio > mu
            mult = eta;
        elseif ratio < 1/mu
            mult = 1/eta;
        else
            mult = 1;
        end
        rho = rho * mult;
        Y = Y / mult;
        if mult ~= 1
            % Re-compute params for X update
            iAc = (Ac + rho * I) \ I;
            pA = A' * iAc;
            decay = lambda * iAc * kappa;
            X_ls = B * pA;
        end
        
    end

    % Stopping criterion (based on primal & dual residuals)
    tol_primal = EPS_ABS * sqrt(n) + ...
        EPS_REL * max(norm(X(:)), norm(X2(:)));
    tol_dual = EPS_ABS * sqrt(n) + ...
        EPS_REL * rho * norm(Y(:));
    if k > 1 && (norm(r(:)) < tol_primal) && (norm(d(:)) < tol_dual)
        % Set k to either to the next kappa estimation index, or nIter
        control_array = [idx_estimate_kappa, nIter];
        k = control_array(find(control_array > k, 1)) - 1;
        % Terminate if all kappa estimation steps are done
        if k == nIter - 1
            loss = loss(1:acc);
            break;
        end
    end
    
end

% Restore scale
X2 = bsxfun(@rdivide, X2, scale');

X2 = gather(X2);
loss = gather(loss);

function d =  f_loss_gpu(x, kappa)
    if x < -kappa
        d = -x - kappa / 2;
    else
        d = (x^2) / kappa / 2;
    end
end

function l =  f_loss_cpu(x, kappa)
    y = max(x, -kappa);
    l = y .* (x - y/2);
    l = l ./ kappa;
    l = sum(l(:));
end

end
