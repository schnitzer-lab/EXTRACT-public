function mask = make_mask(S, fov_size, radius)
% Make mask for each column in S by 
% 1) treating it as image
% 2) smoothing by a disk filter with input radius
% 3) binarizing the the smooth image
% This function is gpu aware.
    filt = double(fspecial('disk', radius)>0); 
    mask = filter_images(S, fov_size, filt, isa(S, 'gpuArray')) > 0;
end