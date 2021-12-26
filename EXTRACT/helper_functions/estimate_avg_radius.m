function avg_radius = estimate_avg_radius(S, fov_size, method)
% Estimate an average cell radius given 2D spatial weights

% Direct method: compute radius by using image axis lengths
% Indirect method: compute areas, then use area = 2*pi*r^2 to find r
if nargin < 3 || isempty(method)
    method = 'indirect';
end

if strcmpi(method, 'direct')
    [l_major, l_minor] = get_image_axis_lengths(S, fov_size);
    radii = sqrt(l_major .* l_minor) / 2;
    avg_radius = double(quantile(radii, 0.5));
elseif strcmpi(method, 'indirect')
    areas = get_cell_areas(S);
    avg_radius = double(quantile(sqrt(areas/pi), 0.5));
end