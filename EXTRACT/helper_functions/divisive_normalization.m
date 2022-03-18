function data = divisive_normalization(data, avg_radius, tol)
% Performs divisive normalization on movie data by first applying a 
% low-pass filter to it and then dividing the original movie by this 
% filter.
%
% Inputs:
%   data: 3-D movie, single type. Conversion from double to single is made
%       if double input is given.
%
%   avg_radius: Estimated radius for an average cell in the movie.
%
%   (optional) tol: The tolerance for the low-pass filter which is defined 
%       as (roughly) as the ratio of the cutoff radius to the average cell 
%       radius. Default: 5.
%
% Outputs:
%   data: Result after divisive per-frame normalization.
%

    % Default for tol
    if ~exist('tol', 'var')
            tol = 5;
    end
    
    % Send data to CPU if on GPU
    is_input_gpuArray = isa(data, 'gpuArray');
    if is_input_gpuArray
        data = gather(data);
    end
    
    % Remove nans
    data = replace_nans_with_zeros(data);
    
    % Work with single precision
    data = single(data);
    
    if gpuDeviceCount > 0
        use_gpu = true;
    else
        use_gpu = false;
    end
    
    smooth_data = spatial_bandpass(data, avg_radius, inf, 1/tol, use_gpu);
    data = data ./ smooth_data;
    
    % Send back to GPU if data was on GPU originally
    data = maybe_gpu(is_input_gpuArray, data);
    
end