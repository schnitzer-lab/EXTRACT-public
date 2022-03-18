function b = get_im_boundary(im, mag_thresh)
    max_val = max(max(im));
%     im_bw = imopen(im > mag_thresh * max_val, strel('disk', 1));
    im_bw = im > mag_thresh * max_val;
    b = bwboundaries(im_bw);
    lens = cellfun(@length, b);
    if ~isempty(lens)
        b = b{find(lens == max(lens), 1)};
    else
        b = [];
    end
end