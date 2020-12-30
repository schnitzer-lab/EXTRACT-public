function tau = estimate_tau(M, q)
% Estimate event time constant from a 2-D matrix with rows as traces
%   M: Input 2-D matrix
%   q: Optional, fraction of pixels to use for estimation
% Returns:
%   tau: estimated time constant
tau=10;
return;

if ~exist('q', 'var')
    q = 0.1;
end
max_lag = 100;  % Be conservative
var_array = var(M, 0, 2);
idx_keep = var_array>quantile(var_array, 1 - q);
% movie is all-zeros if idx_keep is empty
if sum(idx_keep) == 0
    tau = 0;
    return;
end
% Use up to 2000 frames
t_end = min(2000, size(M, 2));
M_subset = M(idx_keep, 1:t_end);
M_centered = bsxfun(@minus, M_subset, quantile(M_subset,0.2,2));
M_long = reshape(M_centered', numel(M_centered), 1);
ac = autocorr(M_long, max_lag);
ac = ac(2:end);  %  Index 1 contains noise variance
d = -ac ./ gradient(ac);

% tau_1, initial estimate
tau_1 = median(d(1:10));
% tau_1, finer estimate
tau_1 = median(d(1:min(length(d),round(tau_1))));

% tau_2
ac_adjusted = medfilt1(ac);
tau_2 = find(ac_adjusted<ac(1)*0.37, 1);
if isempty(tau_2)
    tau = 0;
else
    tau = min(tau_1, tau_2);
end
