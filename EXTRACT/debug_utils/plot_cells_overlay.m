function plot_cells_overlay(cell_images, c, lw, contour_thresh)
    
if nargin < 4 || isempty(contour_thresh)
    contour_thresh = 0.3;
end

if nargin < 3 || isempty(lw)
    lw = 1;
end

if nargin < 2 || isempty(c)
    auto_color = 1;
else
    auto_color = 0;
end

if auto_color
    c = max(rand(1, 3), 0.2);
    c = c / max(c);
end

is_ndSparse = isa(cell_images, 'ndSparse');
% Smooth images
[h, w, k] = size(cell_images);
cell_images_2d = reshape(cell_images, h * w, k);
if is_ndSparse
    cell_images_2d = full(cell_images_2d);
end
cell_images_2d = smooth_images(cell_images_2d, [h, w], 4, 0);
if is_ndSparse
    cell_images_2d = ndSparse(cell_images_2d);
end
cell_images = reshape(cell_images_2d, h, w, k);

for idx = 1:size(cell_images, 3)
    im = full(full(cell_images(:, :, idx)));
    max_val = max(max(im));
    b = bwboundaries(im > contour_thresh * max_val);
    lens = cellfun(@length, b);
    if ~isempty(lens)
        b = b{find(lens == max(lens), 1)};
        hold on;
        plot((b(:,2)), (b(:,1)),'Color', c, 'LineWidth', lw) 
        hold off
    end
end