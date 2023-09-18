function metric = spat_corruption(F, siz, visualize,sparse_array)

    if nargin < 3 || isempty(visualize)
        visualize = false;
    end

    if nargin < 4 || isempty(sparse_array)
        sparse_array = 0;
        F = full(F);
    end

    h = siz(1);
    w = siz(2);
    nk = size(F,2);

    mask_in = F>1e-3;
    nnz_each = full(sum(mask_in,1));
    mean_each = full(sum(mask_in.*F,1)./nnz_each);
    if sparse_array
        metric = zeros(1,size(F,2));
        mask_in = sparse(mask_in);
        F = sparse(double(F));
        for cell = 1:size(F,2)
            mask_in_temp = full(mask_in(:,cell));
            F_temp = full(F(:,cell));
            F_diff = mask_in_temp.*bsxfun(@minus, F_temp, mean_each(cell));
            F_diff = bsxfun(@times, F_diff, sqrt(1./max(mean_each(cell), 1e-2)));
            var_each = sum(F_diff.^2, 1)./nnz_each(cell);
            mask_in_temp = reshape(mask_in_temp,h,w,1);
            F_temp = reshape(F_temp,h,w,1);
            filt = ones(4);%[0, 1, 0; 1, 1, 1; 0, 1, 0];
            filt = filt/sum(filt(:));
            local_mean = imfilter(F_temp,filt, 'replicate');
            F_diff = mask_in_temp.*(F_temp-local_mean);
            
            local_mean = reshape(local_mean, h*w, 1);
            F_diff = reshape(F_diff,h*w,1);
            F_diff = F_diff .* (1./sqrt(max(1e-2, local_mean)));
            
            var_local_each = sum(F_diff.^2, 1)./nnz_each(cell);
            metric(cell) = var_local_each ./ var_each;
        end
        F = reshape(F, h*w, nk);
    else
    F_diff = mask_in.*bsxfun(@minus, F, mean_each);
    F_diff = bsxfun(@times, F_diff, sqrt(1./max(mean_each, 1e-2)));
    var_each = sum(F_diff.^2, 1)./nnz_each;
%     var_each = zeros(nk, 1);
%     for i = 1:nk
%         f = F_diff(:, i);
%         var_each(i) = median(f(f>0));
%     end
    mask_in = reshape(mask_in,h,w,nk);
    F = reshape(F,h,w,nk);
    filt = ones(4);%[0, 1, 0; 1, 1, 1; 0, 1, 0];
    filt = filt/sum(filt(:));
    local_mean = imfilter(F,filt, 'replicate');
    F_diff = mask_in.*(F-local_mean);
    F = reshape(F, h*w, nk);
    local_mean = reshape(local_mean, h*w, nk);
    F_diff = reshape(F_diff,h*w,nk);
    F_diff = F_diff .* (1./sqrt(max(1e-2, local_mean)));
    
    var_local_each = sum(F_diff.^2, 1)./nnz_each;
%     var_local_each = zeros(nk, 1);
%     for i = 1:nk
%         f = F_diff(:, i);
%         var_local_each(i) = median(f(f>0));
%     end
    metric = var_local_each ./ var_each;
    F = reshape(F, h*w, nk);
    end
    
    if visualize
        for i = 24:size(F, 2)
            im = reshape(F(:, i), h, w);
            [x_range, y_range] = get_image_xy_ranges(im, 5);
            im_small = im(y_range(1):y_range(2), x_range(1):x_range(2));
            imagesc(im_small); axis image;colormap jet;
            title(sprintf('Component %d, spat corr: %.2f',  i, metric(i)));
            pause;
        end
    end
end

% other methods
%     h = siz(1);
%     w = siz(2);
%     nk = size(F,2);
%     
%     filt = fspecial('gaussian', [5, 5], 1);
%     F_smooth = imfilter(reshape(F, h, w, nk), filt, 'replicate');
%     F_smooth = reshape(F_smooth, h * w, nk);
%     F_smooth = bsxfun(@rdivide, F_smooth, max(1e-6, max(F_smooth, [], 1)));
%     mask = F_smooth>0.1;
%     X = abs(F - F_smooth) ./ max(F_smooth, F);
%     metric = zeros(1, size(F, 2), 'single');
%     for i = 1:size(F, 2)
%         x = X(mask(:, i), i);
%         metric(i)  = median(x);
%     end
    
    

%     h = siz(1);
%     w = siz(2);
%     mask_in = F>1e-3;
%     nk = size(F,2);
%     nnz_each = sum(mask_in,1);
%     mean_each = sum(mask_in.*F,1)./nnz_each;
%     var_each = sum(mask_in.*F.^2,1)./nnz_each-mean_each.^2;
%     mask_in = reshape(mask_in,h,w,nk);
%     F = reshape(F,h,w,nk);
%     filt = fspecial('gaussian', [5, 5], 2);%ones(5)/25
%     filt = filt/sum(filt(:));
%     F_smooth = imfilter(F,filt);
%     F_diff = mask_in.*(F-F_smooth);
%     F_diff = reshape(F_diff,h*w,nk);
%     var_local_each = sum(F_diff.^2,1)./nnz_each;
%     metric2 = var_local_each./var_each;
%     F = reshape(F, h*w, nk);

