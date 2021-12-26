function M_out = div_norm_filter(M, filter_radius)
% Spatial filtering by divisive normalization, mainly to eliminate 
% neuropil
% M: 3-D movie
% filter_radius: radius for the disk used for filtering
% return M_out: output, obtained by normalizing by the smoothed input
    minval = min(M(:))+1e-6;
    M = M+minval;
    h = fspecial('disk', filter_radius);
    M_smooth = imfilter(M, h, 'replicate');
    M_out = (M)./ (M_smooth);
    % Compute 0.01 and 0.99 quantiles and set outliers to zero
    quants = quantile(M_out(:), [0.05, 0.99]);
    M_out(M_out<quants(1) | M_out>quants(2))=0;
end