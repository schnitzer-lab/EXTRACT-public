function [X2,loss] = fp_solve_nonneg(...
    X, A, B, mask, lambda, kappa, nIter, tol, dum)
% Solve for X using fixed point algorithm inside fast-ADMM routine
% This function is gpu-aware.

eo2 = kappa/2;
et2 = 1/kappa/2;

use_gpu = isa(B, 'gpuArray');

nIter_sub=2;
opt_2=0;

loss = zeros(1,nIter,'single');
I = eye(size(X,2),'single');
[loss, I, X, A, lambda, mask] = maybe_gpu(use_gpu, ...
    loss, I, X, A, lambda, mask);

Ac = A*A';
e = eig(Ac);
lambda_min = e(1);
lambda_max = e(end);

% Compute acceptable upper limit on condition number. This is based on
% the expected condition number of a random gaussian square matrix,
% which is theta(n) (n is # dimensions).
cond_limit_upper = size(Ac,1) / 3;
lambda_min = max(lambda_min, lambda_max / cond_limit_upper);
rho = sqrt(lambda_min*lambda_max)

iAc = (Ac+rho*I)\I;
pA = A'*iAc;
decay = lambda*iAc;
X_ls = B*pA;
X2=X;
X2h=X2;
Y = X*0;
Yh = Y;

nu=0.99;
alpha=1;
c=inf;
f=inf;
for k = 1:nIter
    Y_old=Y;
    X2_old=X2;

%     % Update loss
%     f_before = f;
%     if use_gpu
%         f = arrayfun(@f_loss_gpu, X2 * A - B);
%     else
%         f = f_loss_cpu(X2 * A - B, kappa);
%     end
%     f = sum(f(:));
%     f=f+lambda*sum(X2,1)';
%     loss(k)=f;

    % X fixed-point update
    for i = 1:nIter_sub
        res = X*A-B;
        X = (min(res+kappa,0))*pA+X_ls;
        if ~opt_2
        X = bsxfun(@minus,X,decay);
        end
        X = X+(-Yh+X2h)*iAc*rho; 
    end
    % X2 update
    X2 = max(bsxfun(@minus,X+Yh,opt_2*lambda/rho),0);
    if ~isempty(mask)
        X2 = X2.*mask;
    end
    % Dual update
    diff = X-X2;
    Y = Yh + diff;
    
    % Compute lagrangian
    f_before = f;
    if use_gpu
        f = arrayfun(@f_loss_gpu, X2 * A - B);
    else
        f = f_loss_cpu(X2 * A - B, kappa);
    end
    f = kappa * sum(f(:));
    loss(k)=f;
    
    % Check monotonicity
    c_old = c;
    alpha_old = alpha;
    c = rho*( sum(sum((Y-Yh).^2))+sum(sum((X2-X2h).^2)));
    if c<nu*c_old % Update
        alpha = (1+sqrt(1+4*alpha^2))/2;
        X2h = X2+((alpha_old-1)/alpha)*(X2-X2_old);
        Yh = Y+((alpha_old-1)/alpha)*(Y-Y_old);
    else % Restart
        alpha=1;
        X2h = X2;%X2_old;
        Yh = Y;%Y_old;
        c = c_old/nu;
    end
    % Termination condition
%     if k>1 && (abs(f_before - f) / f_before < tol)
%         loss = loss(1:k);
%         break;
%     end
    
end

X2 = gather(X2);
loss = gather(loss);

function d =  f_loss_gpu(x)
    if x<-kappa
        d = -x-eo2;
    else
        d = (x^2)*et2;
    end
end

function l =  f_loss_cpu(x, kappa)
    y = max(x, -kappa);
    l = y .* (x - y/2);
    l = sum(l(:))/kappa;
end

end
