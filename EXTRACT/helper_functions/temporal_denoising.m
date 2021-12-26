function M_out = temporal_denoising(M, denoising_method)

if nargin < 2 || isempty(denoising_method)
    denoising_method = 'fdr';
end

% Temporal wavelet denoising for 2D or 3D movie matrix
% This is a slow function

    % Number of pixels to be updated at once
    num_pixels_per_chunk = 1000;
    
    % Reshape to 2D if M is 3D
    if ndims(M) == 3
        is_matrix = 0;
        [h, w, n] = size(M);
        M = reshape(M, h*w, n);
        m = h * w;
    else
        is_matrix = 1;
        [m, ~] = size(M);
    end
    
    % Determine num_chunks
    num_chunks = ceil(m / num_pixels_per_chunk);
    
    % Initialize output
    M_out = zeros(size(M), class(M));
    
    % Denoise in chunks
    for i = 1:num_chunks
%         if mod(i, 20) == 0
%             fprintf('%s: Processing %d of %d chunks.. \n', datestr(now), i, num_chunks);
%         end
        idx = select_indices(m, num_chunks, i);
        M_in_this = double(M(idx, :));
        M_out_this = wdenoise(M_in_this',1,  'wavelet', 'fk6',...
            'DenoisingMethod', denoising_method);
%         M_out_this = wdenoise(M_in_this,10,'DenoisingMethod','BlockJS');
        M_out_this = single(M_out_this');%'fk6'
        M_out(idx, :) = M_out_this;
    end
    
    % Keep input and output dims consistent
    if ~is_matrix
        M_out = reshape(M_out, h, w, n);
    end
    
    function clean = swt_denoise(s)
        level = 2;
        orig_len = length(s);
        % Level has to be multiple of min_len
        min_len = 2^level;
        new_len = min_len * ceil(orig_len / min_len);
        n_pad = new_len - orig_len;
        s = [s, zeros(1, n_pad)];
        [swa,swd] = swt(s,level,'db3'); 
        [thr,sorh] = ddencmp('den','wv',s); 
        dswd = wthresh(swd,sorh,thr);
        clean = iswt(swa,dswd,'db1');
        clean = clean(1:orig_len);
    end
    
end