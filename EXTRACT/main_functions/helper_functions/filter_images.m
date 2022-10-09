function S_out = filter_images(S, fov_size, h, use_gpu)
% filter columns of S treating them as images
    [m, n] = size(S);
    if use_gpu 
        GPU_SLACK_FACTOR = 8;
        d = gpuDevice();
        avail_size = d.AvailableMemory / 4 / GPU_SLACK_FACTOR;
        num_chunks = ceil(m * n / avail_size);
    else
        num_chunks = 1;
    end
    % Compute S_smooth
    S_out = S * 0;
    for i = 1:num_chunks
        indices = select_indices(n, num_chunks, i);
        S_small = S(:, indices);
        ims_in = maybe_gpu(use_gpu, reshape(S_small, fov_size(1), ...
            fov_size(2), length(indices)) );
        ims_out = gather(imfilter(ims_in, h));
        S_out(:, indices) = reshape(ims_out, m, length(indices));
        clear ims_in;
    end
end