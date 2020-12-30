function [data] = spatial_gauss_lowpass(data, radius, ...
    f_lower_scale, f_upper_scale, use_gpu)
% Butterworth bandpass filter for multi-dimensional images.

% Null op if filter cutoffs are trivial
if isinf(f_lower_scale) && isinf(f_upper_scale)
    return;
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

% Cutoff frequencies 
% Model the neuron as a gaussian, with sigma~radius/2;
% ex = 2; % number of pixels for transition band
% exf = 1/max(h,w)/ex;
% nfilt = 4*radius;
sigma = radius/2;
% f_corner = 1 / pi / sigma;
% f_lower = f_corner / f_lower_scale;
% f_upper = min(1, f_corner * f_upper_scale);
% 
% f = [0, max(0,f_lower-exf), f_lower+exf, f_upper-exf, min(1, f_upper+exf), 1];
% a = [0, 0, 1, 1, 0, 0];
% b = firpm(nfilt, f, a);
% b2d = zeros(nfilt, nfilt);
% [cx, cy] = meshgrid(1:nfilt, 1:nfilt);
% dist_matrix = sqrt( ((cy-1) / (nfilt-1)*2 - 1).^2 + ((cx-1) / (nfilt-1)*2 - 1).^2);
% for i = 1:nfilt
%     for j = 1:nfilt
%         if dist_matrix(i,j)<=1.05
%             b2d(i,j) = b(round(11-10*dist_matrix(i,j)));
%         end
%     end
% end

% b2d = ftrans2(b);
% subplot(211);
% imagesc(b2d);axis image
% subplot(212)
% freqz2(b2d);
b2d = fspecial('gaussian', (2*radius+1)*[1,1], sigma);
% b2d = b2d-mean2(b2d);
b2d = b2d / sum(b2d(:));

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
    % Filter
    data_small = imfilter(data_small, b2d, 'replicate');

    % Update current chunk
    if use_gpu && ~is_input_gpuArray
        data_small = gather(data_small);
    end
    data(:, :, idx_begin:idx_end) = data_small;
end
