function [circularities, eccentricities] = ...
        get_circularity_metrics(S, fov_size, threshold)
    if nargin < 3 || isempty(threshold)
        threshold = 0.3;
    end
    k = size(S, 2);
    images = reshape(S, fov_size(1), fov_size(2), k);
    circularities = nan(1, k, 'single');
    eccentricities = nan(1, k, 'single');
    for i = 1:k
        bw_image = images(:,:,i)>threshold;
        stats = regionprops(bw_image, 'Area', 'Perimeter', 'MajorAxisLength', 'MinorAxisLength');
        areas = [stats.Area];
        % Choose the component with max area
        stats = stats(find(areas == max(areas), 1));
        if ~isempty(stats)
            area = stats.Area;
            perimeter = stats.Perimeter;
            eccentricities(i) = stats.MajorAxisLength / stats.MinorAxisLength;
            % Circularity is maximum 1 for circles
            circularities(i) = 4*pi* area / perimeter^2;
        end
    end
    eccentricities(isnan(eccentricities)) = inf;
    circularities(isnan(circularities)) = inf;
end