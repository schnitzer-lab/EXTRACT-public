function [x_range, y_range] = get_image_xy_ranges(im, ex)
    if ~exist('ex', 'var')
        ex = 0;
    end
    [h,w] = size(im);
    idx_x_occupied = find(sum(im, 1)>0.05);
    x_range = [max(1, idx_x_occupied(1)-ex), min(w, idx_x_occupied(end)+ex)];
    idx_y_occupied = find(sum(im, 2)>0.05);
    y_range = [max(1, idx_y_occupied(1)-ex), min(h, idx_y_occupied(end)+ex)];
    
    