function [preds, w] = ml_predict_labels(features, labels, do_zscoring)
    if nargin < 3 || isempty(do_zscoring)
        do_zscoring = false;
    end
    
    if do_zscoring
        % replace infs with 0s
        infs = isinf(features);
        features(infs) = 0;
        features = zscore(features, 0, 1);
        features(infs) = 0;
    end
    idx_l = find(labels ~= 0);
    labels(labels == -1) = 0;
%     svm = fitcsvm(features(idx_l, :), labels(idx_l), ...
%         'kernelfunction', 'rbf', 'standardize', true,...
%         'BoxConstraint', 1);
    mdl = fitclinear(features(idx_l, :), labels(idx_l), ...
        'learner', 'logistic', 'regularization', 'lasso',...
         'ClassNames', [0, 1], 'Prior', 'empirical');
%     mdl = fitcdiscr(features(idx_l, :), labels(idx_l), ...
%         'discrimtype', 'linear', 'gamma', 1);

    [~, preds] = predict(mdl, features);
    preds = preds(:, 2);
    w = mdl.Beta;
%     w = zeros(size(features, 2) + 1, 1);
end