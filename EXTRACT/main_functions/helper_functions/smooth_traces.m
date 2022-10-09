function T_out = smooth_traces(T, smoothing_factor)
    if nargin < 2 || isempty(smoothing_factor)
        smoothing_factor = 1;
    end
    num_cells = size(T, 1);
    T_out = zeros(size(T), class(T));
    for i = 1:num_cells
        T_out(i, :) = swt_denoise(T(i, :), smoothing_factor);
    end
end