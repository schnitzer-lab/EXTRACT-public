function [idx_active_label, preds, competences, w] = ...
    ask_for_label(features, labels, ml_labels, varargin)
    labels(labels == 2) = 1;
    ml_labels(ml_labels == 2) =1;
    method = 'min_conf';
    do_zscoring = true;
    D = [];
    
    if ~isempty(varargin)
        for k = 1:length(varargin)
            vararg = varargin{k};
            if ischar(vararg)
                switch lower(vararg)
                    case 'method'
                        method = varargin{k+1};
                    case 'distances'
                        D = varargin{k+1};
                    case 'normalize'
                        do_zscoring = varargin{k+1};
                end
            end
        end
    end
    
    n = size(features, 1);

    % Train classifier to get predictions
    [preds, w] = ...
        ml_predict_labels(features, ml_labels, do_zscoring);
    
%     Get competence of the classifier for classification
%     Do N shuffles and compare each prediction
%     N = 10;
%     preds_mat= zeros(n, N);
%     idx_l = find(ml_labels ~= 0);
%     change_prob = 0.01;
%     for j = 1:N
%         labels_this = zeros(n, 1);
%         labels_this(idx_l) = change_labels(ml_labels(idx_l), change_prob);
%         idx_l_sub = randsample(idx_l, round(length(idx_l)*0.8));
%         labels_this(idx_l_sub) = ml_labels(idx_l_sub);
%         [preds_this, ~] = ...
%             ml_predict_labels(features, labels_this, do_zscoring);
%         preds_mat(:, j) = preds_this;
%     end 
%     Compare the mean std of preds to that of uniform [0, 1]
%     std_preds = std(preds_mat, 1, 2);
%     std_uniform = 1 / sqrt(12);
%     competences = 1 - std_preds / std_uniform;
%     y_hats = preds_mat > 0.5;
%     p1 = sum(y_hats, 2) / N;
%     ent = -p1 .*log2(p1) - (1-p1).*log2(1-p1);
%     ent(isnan(ent)) = 0;
%     competences = 1-ent;
competences = preds;
    
    confidences = abs(preds - 0.5);
    % Existing ml labels are excluded
    %confidences(ml_labels ~= 0) = inf; % Return to this part later!
    
    % Existing labels are excluded
    confidences(labels ~= 0) = inf;

    if strcmpi(method, 'min_conf')
        [~, idx_active_label] = min(confidences);
    elseif strcmpi(method, 'core_set')
        s = find(confidences == inf); % Start with previously labeled points
        [~, idx_sort] = sort(confidences);  % Check for confidence rank
        acc = 0;
        while true
            acc = acc+1;
            idx_active_label = sample_most_distant(D, s);
            % Check confidence rank
            conf_rank = find(idx_sort == idx_active_label);
            % Enforce high rank (within 30th percentile)
            if conf_rank / sum(confidences<inf) > 0.3
                s(end+1) = idx_active_label; %#ok<*AGROW>
            else
                break;
            end
        end
    elseif strcmpi(method, 'random')
        idx_active_label = randsample(find(confidences < inf), 1);
    end
    
    function idx_sample = sample_most_distant(D, s)
        % Get a sub-matrix with distances from s
        D_sub = D(s, :);
        % Get minimum distance from the set s for each candidate
        min_dists = min(D_sub, [], 1);
        [~, idx_sample] = max(min_dists);
    end

    function labels = change_labels(labels_in, change_prob)
        ln = length(labels_in);
%         ch = false(ln, 1);
%         ch(randsample(ln, ceil(ln * change_prob))) = true;
        ch = rand(ln, 1) < change_prob;
        % map labels to {0,1}
        labels = logical((labels_in + 1) / 2);
        labels = xor(labels, ch);
        % Map back to -1, 1
        labels = round(labels*2 - 1);
    end

end
