function T_out = upsample_traces(T_in, n_orig,n)
    
    % Note that T_in/T_out are assumed to be a 2D matrix of the form n_times x n_cell!
    % n_orig is the original movie's temporal size
    % n is the downsampled movie's size

    T_out = interp1(round(linspace(1, n_orig, n)), T_in, 1:n_orig);

end