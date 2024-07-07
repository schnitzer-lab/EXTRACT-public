function roc = compute_ROC_curve(event_times_ground,T,parallel,tau)
% Compute ROC curve (tpr vs fpr) for given ground truth and estimated param
% pair. The indices of ground truth and estimated params must match.

if isempty(T)
    roc = [];
    return;
end

if nargin<3 || isempty(parallel)
    parallel = 1;
end

if nargin<4 || isempty(tau)
    tau = 10;
end

% Make sure T is double
T = double(T);
num_cells = size(T, 1);
T = T ./ max(T,[],2);


sigmas_range = [0.01:0.01:1];

roc = zeros(2, length(sigmas_range), num_cells);
if parallel
    parfor idx_sigma = 1:length(sigmas_range)
        sigma = sigmas_range(idx_sigma);
        event_times = {};
        for i = 1:size(T,1)
            event_times{i} = extract_events_deconv(T(i,:),sigma,tau);
        end
        [tpr, fpr] = match_events_to_ground(event_times_ground, event_times);

        
        roc(:, idx_sigma, :) = [tpr;fpr];
    end
else
    for idx_sigma = 1:length(sigmas_range)
        sigma = sigmas_range(idx_sigma);
        event_times = {};
        for i = 1:size(T,1)
            event_times{i} = extract_events_deconv(T(i,:),sigma);
        end
        [tpr, fpr] = match_events_to_ground(event_times_ground, event_times);
        
        roc(:, idx_sigma, :) = [tpr;fpr];
    end
end

end