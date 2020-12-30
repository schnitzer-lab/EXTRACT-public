function metric = get_eccentricity_metric(S, fov_size)
    [l_major, l_minor] = get_image_axis_lengths(S, fov_size);
    metric = l_major ./ l_minor;
    metric(isnan(metric)) = inf;
end