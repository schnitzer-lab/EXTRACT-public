function kappa = kappa_of_epsilon(eps)
    eps = max(eps, 0.001);
    kappa = -0.3775*log(eps) - 0.0597*eps + 0.0544;
    
%     % In order to find coefficients, we fit a linear model as follows:
%     % First get the function in the expensive way (linear interpolation,
%     % high evaluation cost)
%     eps_of_kappa = @(x) 1-1./ (normpdf(x)./x+normcdf(x));
%     kap = 0.01:0.01:3;
%     eps = eps_of_kappa(kap);
%     kofe = fit(eps', kap', 'linearinterp');
%     % Linear fit using log(eps) and eps
%     eps_fit = 0.001:0.01:0.99;
%     X = [log(eps_fit'), eps_fit'];
%     y = kofe(eps_fit);
%     f = fitlm(X, y);
%     kap_est = predict(f, X);
%     % Plot and see the fit
%     plot(eps, kap);
%     hold on
%     plot(eps_fit, kap_est);
%     hold off;
