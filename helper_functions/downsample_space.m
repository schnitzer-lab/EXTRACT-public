function M_out = downsample_space(M, df)
    [h, w, ~] = size(M);
    y_array = 1:df:h - mod(h, df);
    x_array = 1:df:w - mod(w, df);
    for ky = 1:df
        for kx = 1:df
            if ky*kx == 1
                M_out = M(y_array + ky - 1, x_array + kx - 1, :);
            else
                M_out = M_out + M(y_array + ky - 1, x_array + kx - 1, :);
            end
        end
    end
    M_out = M_out / df^2;
end