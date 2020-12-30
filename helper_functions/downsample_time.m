function M_out = downsample_time(M, df)
    % Reshape to 2d if 3d
    if ndims(M) == 3
        [h,w,t] = size(M);
        is_input_3d = true;
        M = reshape(M, h*w, t);
    else
        t = size(M, 2);
        is_input_3d = false;
    end
    
    t_end = t - df + 1;
    time_array = 1:df:t_end;
    for i = 1:df
        if i == 1
            M_out = M(:, time_array + i - 1);
        else
            M_out = M_out + M(:, time_array + i - 1);
        end
    end
    M_out = M_out / df;
    
    % Reshape back to 3d
    if is_input_3d
        M_out = reshape(M_out, h,w,size(M_out, 2));
    end
end