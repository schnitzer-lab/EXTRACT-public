function [X,loss] = fp_solve(X,A,B, mask, lambda, kappa, nIter, tol, compute_loss, use_gpu, transpose_B)

eo2 = kappa / 2;
et2 = 1 / kappa / 2;

[X, A, B] = maybe_gpu(use_gpu, X, A, B);

if ~transpose_B
    B = B';
end
A = A';
X = X';
lambda = lambda';

I = maybe_gpu(use_gpu, eye(size(A,2),'single'));
Ac = A'*A;

iAc = (Ac)\I;
pA = iAc*A';
decay = iAc*lambda;%*mu;
X_ls = pA*B;

loss = maybe_gpu(use_gpu, zeros(1,nIter,'single'));


for k = 1:nIter    
    % T1 fixed-point update
    res = A*X-B;
    X = pA*(min(res+kappa,0))+X_ls;
    X = bsxfun(@minus,X,decay);
    if compute_loss
        l = arrayfun(@f_loss_gpu, res);
        loss(k) = sum(l(:));
    end
%     X(X<0)=0;
end
X = gather(X');
loss = gather(loss);

function d =  f_loss_gpu(x)
    if x < -kappa
        d = -x - eo2;
    else
        d = (x^2) * et2;
    end
end

end