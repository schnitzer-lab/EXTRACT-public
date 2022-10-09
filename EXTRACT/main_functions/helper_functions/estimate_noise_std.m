function noise_std = estimate_noise_std(data, time_axis, use_gpu)

if nargin < 3
    use_gpu = isa(data, 'gpuArray');
end

if nargin < 2
    time_axis = 2;
end

% If data is already on GPU, we deal differently
is_input_gpuArray = isa(data, 'gpuArray');

% Use same frequency scale in x,y
if time_axis == 2
    [m, n] = size(data);
else
    [n, m] = size(data);
end
noise_std = zeros(m, 1, 'single');

% Chunk data so that we don't run out of memory
if m > 1
    if use_gpu
        slack_factor = 20;
        d = gpuDevice();
        avail_size = d.AvailableMemory / 4 / slack_factor;
    else
        slack_factor = 15;
        f = get_free_mem;
        avail_size = f / 4 / slack_factor;
    end
else
    avail_size = inf;
end

if isinf(avail_size)
    n_chunks = 1;
else
    n_chunks = ceil(n * m / avail_size);
end

for i = 1:n_chunks
    idx = select_indices(m, n_chunks, i);
    if time_axis == 2
        data_small = data(idx, :);
    else
        data_small = data(:, idx);
    end
    % Send to GPU if use_gpu=true and data not already on GPU
    data_small = maybe_gpu(use_gpu & ~is_input_gpuArray, data_small, time_axis);
    
	noise_std(idx) = gather(estimate_noise_std_func(data_small, time_axis));
end

function noise_std = estimate_noise_std_func(M, fft_axis)
% Estimate noise std of each row of a matrix

cutoff_freq = 0.5;  % normalized to 1

nn=(size(M,fft_axis));
N = ceil(nn/2);  % fft half length
noise_start_freq = round(cutoff_freq*N);
fftM = fft(M, nn, fft_axis);
if fft_axis == 2
    fftM = fftM(:, 1:N);
    fftM = abs(fftM .* conj(fftM));
    fftM(:, 1) = fftM(:, 1)/2;  % zero freq component is double counted
    fftM = fftM / N / 2; %  normalize
    fftM = fftM(:, noise_start_freq:end);
%     plot(sqrt(mean(fftM, 1)));
else
    fftM = fftM(1:N, :);
    fftM = abs(fftM .* conj(fftM));
    fftM(1, :) = fftM(1, :)/2;  % zero freq component is double counted
    fftM = fftM / N / 2; %  normalize
    fftM = fftM(noise_start_freq:end, :);
end

noise_var = mean(fftM, fft_axis); 
% Deprecated below (was alternative to mean)
%median(fftM, fft_axis)/log(2); (Power is power-law distributed, median is ln(2)*mean)
noise_std = sqrt(noise_var);
noise_std = noise_std(:); % make column vector

end

end


