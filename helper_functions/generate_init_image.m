function s_2d = generate_init_image(Mt, h, w, ind_max, thresh, ex)
    s_init = zeros(h*w,1,'single');
    
    %% method 1
    %Calculate the pairwise temporal correlation between the max_pixel
%     %and all other pixels
%     t_init = Mt(:,ind_max);
%     t_init = t_init / norm(t_init);
%     s_corr = t_init'*Mt;
%     s_corr = s_corr ./sqrt(sum(Mt.^2,1));
%     % autocorrelation is 1, set it zero to not skew normalization
%     s_corr(ind_max) = 0;
% %     s_corr(ind_max) = 0;
%     s_corr = s_corr / max(s_corr);
%     % We effectively set the autocorrelation to the next highest correlation value
%     s_corr(ind_max) = 1;
%     %Find the indeces of the pixels that have a temporal correlation
%     %with the max_pixel above a certain threshold
%     s_corr_ind = find(s_corr>thresh);
%     %Now find the value of each of these correlated pixels at time t=t_max,
%     %when max_pixel is at its maximum
% %     [~, t_max] = max(Mt(:,ind_max));
% %     s_init(s_corr_ind) = Mt(t_max,s_corr_ind);
%     s_init(s_corr_ind) = s_corr(s_corr_ind);
    
    %% method 2
    % Get a relevant region of the movie
    [y, x] = ind2sub([h, w], ind_max);
    y_range = max(1, y-ex):min(h, y+ex);
    x_range = max(1, x-ex):min(w, x+ex);
    h_sub = length(y_range);
    w_sub = length(x_range);
    n = size(Mt, 1);
    pix_idx_lookup = reshape(1:h*w, h, w);
    pix_idx = pix_idx_lookup(y_range, x_range);
    M_sub = Mt(:, pix_idx);
%     M_sub = reshape(M_sub, h_sub, w_sub, n);
    
    % Compute correlation image
    % Center
    M_sub = bsxfun(@minus, M_sub, mean(M_sub, 2));
    % Normalize
    M_sub = bsxfun(@rdivide, M_sub, max(1e-6, sqrt(sum(M_sub.^2, 2))));
    s = (M_sub(:, find(pix_idx==ind_max))' * M_sub)';
    % Normalize max to 1
    im = s / max(s);
    im = reshape(im, h_sub, w_sub);
    
    
%     sigma = 2;
%     psf = fspecial('gaussian', ceil(sigma*4+1), sigma);
%     ind_nonzero = (psf(:)>=max(psf(:,1)));
%     psf = psf-mean(psf(ind_nonzero));
%     psf(~ind_nonzero) = 0;
%     M_sub = imfilter(M_sub, psf, 'replicate');
%     im = correlation_image(M_sub);

%     options.center_psf = true;
%     options.d1 = h_sub;        % image height
%     options.d2 = w_sub;        % image width
%     options.gSig = 3;  % width of the gaussian kernel approximating one neuron
%     options.gSiz = 8;    % average size of neurons
%     im = correlation_image_endoscope(reshape(M_sub, h_sub * w_sub, n), options);

    % Threshold in the correlation image
    im_thresh = im;
    im_thresh(im_thresh < thresh) = 0;
    % Set init image to the thresholded correlation image
    s_init(pix_idx) = im_thresh(:);

    %Extract the largest connected component
    F_temp = reshape(s_init,h,w);
    CC = bwconncomp(F_temp);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    max_comp = find(numPixels==max(numPixels));
    for m=1:size(numPixels,2)
        if m ~= max_comp
            F_temp(CC.PixelIdxList{m})=0;
        end
    end
    s_init = reshape(F_temp,h*w,1);
    s_2d = reshape(s_init, h, w);
    s_2d = s_2d / max(s_2d(:));  
%     clf;
%     imagesc(im);axis image; colormap jet;colorbar;
%     pause;
end