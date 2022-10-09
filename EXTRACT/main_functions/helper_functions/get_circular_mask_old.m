function mask = get_circular_mask(M)
% Get circular mask for movies with GRIN lens
% Mask radius is computed automatically based on an intensity threshold

    intensity_cutoff_factor = 8;
    [h,w,~] = size(M);
    m = mean(M, 3);

    nf = min(h, w);
    [cx, cy] = meshgrid(1:w, 1:h);
    dist_matrix = sqrt((cy - nf / 2).^2 + (cx - nf / 2).^2);
    % Compute mean intensity at each radial coordinate value
    intensities = zeros(1, floor(nf/2));
    for r = 1:floor(nf/2)
        r_small = r-1/2;
        r_big = r + 1/2;
        is_pixel_in_annulus = (dist_matrix>=r_small) & (dist_matrix <= r_big);
        intensities(r) = mean(m(is_pixel_in_annulus));
    end
    % Find distance from center to truncate data
    mini = min(intensities);
    maxi = max(intensities);
    truncate_dist = find(intensities< mini + (maxi-mini)/intensity_cutoff_factor, 1);
    mask = dist_matrix < truncate_dist;
end