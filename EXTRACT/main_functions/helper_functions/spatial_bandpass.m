function [data, power_retained_spectrum] = spatial_bandpass(data, radius, ...
    f_lower_scale, f_upper_scale, use_gpu, smoothing_ratio)
% Butterworth bandpass filter for multi-dimensional images.


% Null op if filter cutoffs are trivial
if isinf(f_lower_scale) && isinf(f_upper_scale)
    power_retained_spectrum = 1;
    return;
end

% higher scale means more smoothing in the respective dimension
if ~exist('smoothing_ratio', 'var')
    scale_y = 1;
    scale_x = 1;
else
    if smoothing_ratio > 1
        scale_x = smoothing_ratio;
        scale_y = 1;
    else
        scale_x = 1;
        scale_y = 1/smoothing_ratio;
    end
end

if ~exist('use_gpu', 'var')
    use_gpu = isa(data, 'gpuArray');
end

% If data is already on GPU, we deal differently
is_input_gpuArray = isa(data, 'gpuArray');

is_2d = ismatrix(data);

% Use same frequency scale in x,y
if is_2d
    [h, w] = size(data);
    t = 1;
else
    [h, w, t] = size(data);
end
% degree of the Butterworth polynomial
n = 4;
% fft dimensions
nf = 2^nextpow2(max(h,w));
hf = nf;% + (mod(h,2)==0);
wf = nf;% + (mod(w,2)==0);

% Cutoff frequencies 
% Model the neuron as a gaussian, with sigma~radius/2;
sigma = radius/2;
f_corner = 1 / pi / sigma;
f_lower = f_corner / f_lower_scale;
f_upper = f_corner * f_upper_scale;

% Create butterworth band-pass filter
[cx, cy] = meshgrid(1:wf, 1:hf);
dist_matrix = sqrt(( scale_y*((cy-1) / (hf) - 1 / 2)).^2 + ( scale_x*(cx-1) / (wf) - 1 / 2).^2);
% Zero distance might cause a NaN in hpf, threshold it above zero
dist_matrix = max(dist_matrix, 1e-6);
lpf = 1 ./ (1 + (dist_matrix / f_upper).^(2 * n));
hpf = 1 - 1 ./ (1 + (dist_matrix / f_lower).^(2 * n));
bpf = single(lpf .* hpf);
power_retained_spectrum = (sum(bpf(:).^2) / hf/wf);
bpf = maybe_gpu(use_gpu, bpf);

% Chunk data in time so that we don't run out of memory
if use_gpu
    slack_factor = 30;
    d = gpuDevice();
    avail_size = d.AvailableMemory / 4 / slack_factor;
else
    slack_factor = 150;
    f = get_free_mem;
    avail_size = f / 4 / slack_factor; 
end
n_chunks = ceil(t * hf * wf / avail_size);
chunk_size = ceil(t / n_chunks);
if is_2d
    n_chunks = 1;
    chunk_size = 1;
end

for i = 1:n_chunks
    idx_begin = (i - 1) * chunk_size + 1;
    idx_end = min(t, i * chunk_size);
    data_small = data(:, :, idx_begin:idx_end);
    % Send to GPU if use_gpu=true and data not already on GPU
    data_small = maybe_gpu(use_gpu & ~is_input_gpuArray, data_small);
    
    % pad
    pad_each_h = floor((hf-h)/2);
    pad_each_w = floor((wf-w)/2);
    data_small = padarray(data_small, [pad_each_h, pad_each_w],'symmetric', 'both');
    % fft
    data_small = fft2(data_small, hf, wf);
    data_small = fftshift(data_small);
    % Filter
    data_small = bsxfun(@times, data_small, bpf);
    data_small = ifftshift(data_small);
    % ifft
    data_small = ifft2(data_small, hf, wf);
    data_small = real(data_small);
    % unpad
    if is_2d
        data_small = real(data_small((pad_each_h+1):(pad_each_h+h),(pad_each_w+1):(pad_each_w+w)));
    else
        data_small = real(data_small((pad_each_h+1):(pad_each_h+h),(pad_each_w+1):(pad_each_w+w), :));
    end

    % Update current chunk
    if use_gpu && ~is_input_gpuArray
        data_small = gather(data_small);
    end
    data(:, :, idx_begin:idx_end) = data_small;
end
