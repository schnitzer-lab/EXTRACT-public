function [l_major, l_minor] = get_image_axis_lengths(S, fov_size, threshold)
    if nargin < 3 || isempty(threshold)
        threshold = 0.2;
    end
    k = size(S, 2);
    images = reshape(S, fov_size(1), fov_size(2), k);
    l_major = nan(1, k, 'single');
    l_minor = nan(1, k, 'single');
    for i = 1:k
        bw_image = images(:,:,i)>threshold;
        stats = regionprops(bw_image, 'Area', 'MajorAxisLength', 'MinorAxisLength');
        areas = [stats.Area];
        % Choose the component with max area
        stats = stats(find(areas == max(areas), 1));
        if ~isempty(stats)
            l_major(i) = stats.MajorAxisLength;
            l_minor(i) = stats.MinorAxisLength;
        end
    end
end