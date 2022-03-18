function eps = eps_func(d, k, v, alpha, apply_limits)
    if ~exist('apply_limits', 'var')
        apply_limits = true;
    end
%     fk = @(x) normpdf(x)./normcdf(x)+x;
%     eps_of_kappa = @(x) 1-1./ (normpdf(x)./x+normcdf(x));
%     e0 = eps_of_kappa(k);
    normpdfk = normpdf(k);
    normcdfk = normcdf(k);
    fk = normpdfk ./ normcdfk + k;

    e0 = 1-1./(normpdfk./k+normcdfk);
    

    correction = 0;
   
    % Use precomputed functions of v for v=0
    if v==0
        normcdfv = 0.5;
        normpdfv = 0.3989;
    else
        normcdfv = normcdf(v);
        normpdfv = normpdf(v);
    end
    numerator = 1 - (1-e0).*normcdfv - (d + correction);
    denominator = normcdfv - (alpha * normpdfv) .* fk;
    
    eps = e0 - numerator ./ denominator;
    eps = min(0.99, max(0.001, eps));
    if apply_limits 
%         eps(eps < 0.3 & eps > 0.1) = 0.3;
        eps(eps < 0.5 & eps > 0.3) = 0.5;
        eps(eps < 0.7 & eps > 0.5) = 0.7;
        eps(eps < 0.9 & eps > 0.7) = 0.9;
    end
end



% function eps = eps_func(d, k)
%     slope_2 = normpdf(0)*0.1;
%     f = @(x) normpdf(x)+x.*normcdf(x);
%     
%     f2_pre = @(d, k, x) 1-(d - slope_2.*x.*k./normcdf(k))./ ...
%         (normcdf(0)-slope_2.*x.*f(k)./normcdf(k));
%     eps = min(0.99, max(0.05, f2_pre(d, k, 1)));
% end
