function data= imwiener(data, use_gpu)
% Wiener filter for 3-D data.

% Wiener filter neighborhood
nhood = [7,7];

if ~exist('use_gpu', 'var')
    use_gpu = isa(data, 'gpuArray');
end

% If data is already on GPU, we deal differently
is_input_gpuArray = isa(data, 'gpuArray');

is_2d = ismatrix(data);
if is_2d
    [h, w] = size(data);
    t = 1;
else
    [h, w, t] = size(data);
end

% If using GPU, chunk data in time so that we don't run out of memory
if use_gpu && ~is_2d
    slack_factor = 10;
    d = gpuDevice();
    avail_size = d.AvailableMemory / 4 / slack_factor;
    n_chunks = ceil(t * h * w / avail_size);
    chunk_size = ceil(t / n_chunks);
else
    n_chunks = 1;
    if is_2d
        chunk_size = 1;
    else
        chunk_size = t;
    end
end

for i = 1:n_chunks
    idx_begin = (i - 1) * chunk_size + 1;
    idx_end = min(t, i * chunk_size);
    data_small = data(:, :, idx_begin:idx_end);
    % Send to GPU if use_gpu=true and data not already on GPU
    data_small = maybe_gpu(use_gpu & ~is_input_gpuArray, data_small);
    data_small = filtfunc(data_small, nhood);
    % Update current chunk
    if use_gpu && ~is_input_gpuArray
        data_small = gather(data_small);
    end
    data(:, :, idx_begin:idx_end) = data_small;
end

    function data_out = filtfunc(data, nhood)
        % Taken from MATLAB's wiener2.m.
        ones_filter = ones(nhood);
        local_mean = imfilter(data, ones_filter) / prod(nhood);
        % Estimate of the local variance of f.
        local_var = imfilter(data.^2, ones_filter) / prod(nhood) - local_mean.^2;
        % Estimate the noise power if necessary.
        p_noise = mean2(local_var);

        data_out = data - local_mean;
        data = local_var - p_noise; 
        data = max(data, 0);
        local_var = max(local_var, p_noise);
        data_out = data_out ./ local_var;
        data_out = data_out .* data;
        data_out = data_out + local_mean;
    end

end