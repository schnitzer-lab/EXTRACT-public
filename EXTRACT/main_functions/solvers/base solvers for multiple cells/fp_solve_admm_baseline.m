function [X2,loss] = fp_solve_admm_baseline(X, A, B, mask, lambda, kappa, nIter, ...
        check_every, compute_loss, use_gpu, transpose_B,baseline)
% Solve for X using fixed point algorithm inside fast-ADMM routine
% This function is gpu-aware.

eo2 = kappa / 2;
et2 = 1 / kappa / 2;
RHO_UPDATE_FREQ = inf;
EPS_REL = 1e-3;
EPS_ABS = 1e-6;
iter_check_convergence = 50;

% Params for adaptive rho
eta = 3;
mu = 1.2;

nIter_sub = 1;

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
% fprintf('min: %d, max:%d\n', lambda_min, lambda_max)
% Compute acceptable upper limit on condition number. This is based on
% the expected condition number of a random gaussian square matrix,
% which is theta(n) (n is # dimensions).
cond_limit_upper = size(Ac, 1) / 3;
lambda_min = max(lambda_min, lambda_max / cond_limit_upper);
rho = sqrt(lambda_min * lambda_max);
iAc = (Ac + rho * I) \ I;
pA = A' * iAc;
decay = lambda * iAc * kappa;
X_ls = B * pA;

if check_every == 0
    temp_baseline = min(0,quantile(X_ls,baseline,1));
end

X2 = X;
Y = X * 0;
n = numel(X);  % Problem dimension

for k = 1:nIter
    % X fixed-point update
    for i = 1:nIter_sub
        res = X * A - B;
        if use_gpu
            X = arrayfun(@fp_op, res);
        else
            X = min(res + kappa, 0);
        end
        X = X * pA + X_ls;
        X = bsxfun(@minus, X, decay);
        X = X + (-Y + X2) * iAc * rho; 
    end
    % X2 update
    X2_m1 = X2;
    X2 = X + Y;

    if check_every == 0
        X2 = max(X2,temp_baseline);
    else
        X2 = max(X2,min(0,quantile(X2,baseline,1)));
    end

    if ~isempty(mask)
        X2 = X2 .* mask;
    end
    % Dual update
    Y = Y + X - X2;
    % Compute loss
    if compute_loss
        if use_gpu
            f = arrayfun(@f_loss_gpu, X2 * A - B);
        else
            f = f_loss_cpu(X2 * A - B, kappa);
        end
        f = sum(f(:));
        penalty_term = bsxfun(@times, X2, lambda);
        f = f + sum(penalty_term(:));
        loss(k)=f;
    end
    
    % Rho update
    if mod(k,RHO_UPDATE_FREQ) == 0
        % Primal and dual residuals
        r = X - X2;
        d = rho * (X2 - X2_m1);
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
    if k > iter_check_convergence
        r = X - X2;
        d = rho * (X2 - X2_m1);
        tol_primal = EPS_ABS * sqrt(n) + ...
            EPS_REL * max(norm(X(:)), norm(X2(:)));
        tol_dual = EPS_ABS * sqrt(n) + ...
            EPS_REL * rho * norm(Y(:));
        if  (norm(r(:)) < tol_primal) && (norm(d(:)) < tol_dual)
            loss = loss(1:k);
            break;
        end
    end
    
end

% Restore scale
X2 = bsxfun(@rdivide, X2, scale');

X2 = gather(X2);
loss = gather(loss);

function d =  f_loss_gpu(x)
    if x < -kappa
        d = -x - eo2;
    else
        d = (x^2) * et2;
    end
end

function l =  f_loss_cpu(x, kappa)
    y = max(x, -kappa);
    l = y .* (x - y/2);
    l = sum(l(:)) / kappa;
end

function y = fp_op(x)
    y = x + kappa;
    if y > 0
        y = y * 0;
    end
end


end
