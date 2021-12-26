function st_corr_metrics = get_st_corr_metrics(M, S, T, fov_size, avg_radius)

    h = fov_size(1);
    w = fov_size(2);
    n = size(M, 2);
    n_cells = size(S, 2);
    
    M = reshape(M, h, w, n);
    ims = reshape(S, h, w, n_cells);
    
    st_corr_metrics = zeros(3, n_cells);
    
    for i=1:n_cells
        [st_corr_arr, ~] = get_st_corr(M, ims(:, :, i), ...
            T(i, :), avg_radius);
        st_corr_metrics(:, i) = quantile(st_corr_arr, [0.1, 0.5, 0.9]);
    end

end