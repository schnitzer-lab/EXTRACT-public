function S_out = smooth_images(S, fov_size, filter_radius, use_gpu, use_medfilt)

if nargin < 5 || isempty(use_medfilt)
    use_medfilt = false;
end

    % Smooth columns of S with a gaussian or median filter
    window_size = ceil(filter_radius * 2 + 1);
    if ~use_medfilt
        h = fspecial('gaussian', [window_size, window_size],...
         filter_radius / 2.5);
     S_out = filter_images(S, fov_size, h, use_gpu);
    else
        S_out = zeros(size(S), class(S));
        for i = 1:size(S, 2)
            ex = 2;
            im = reshape(S(:, i), fov_size(1), fov_size(2));
            bw_im = im>0.1;
            % Return 0 if image is zeroed itself
            if sum(bw_im(:)) > 0
                [x_range, y_range] = get_image_xy_ranges(bw_im, ex);
                x_range = x_range(1):x_range(2);
                y_range = y_range(1):y_range(2);
                im_small = im(y_range, x_range);
                im_small = medfilt2(im_small, [5, 5]);
                im = zeros(size(im), class(im));
                im(y_range, x_range) = im_small;
                S_out(:, i) = reshape(im, prod(fov_size), 1);
            end
        end
    end
end