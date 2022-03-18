function [M_out, fov_occupation] = get_current_partition(...
    M, npx, npy, npt, overlap, idx)
% Slice the movie in the image dimensions to get current partition.
%   M: 3-D movie matrix
%   npx: number of partititons in the x dimension
%   npy: number of partititons in the y dimension
%   overlap: width of the overlap between adjacent partitions
%   idx: current partition index
% returns:
%   M_out: output 3-D movie matrix, sliced according to inputs
%   fov_occupation: Binary 2-D array with 1's only for the current
%   rectangular partitioned region
    [h, w, t] = get_movie_size(M);
    % npt is either < t or =t
    if isempty(npt) || npt > t
        npt = t;
    end
    blocksize_x = ceil((w + (npx - 1) * overlap) / npx);
    blocksize_y = ceil((h + (npy - 1) * overlap) / npy);
    [idx_partition_y, idx_partition_x] = ind2sub([npy, npx], idx);
    x_begin = (idx_partition_x - 1) * (blocksize_x - overlap) + 1;
    x_end = min(x_begin + blocksize_x - 1, w);
    x_keep = x_begin:x_end;
    y_begin = (idx_partition_y - 1) * (blocksize_y - overlap) + 1;
    y_end = min(y_begin + blocksize_y - 1, h);
    y_keep = y_begin:y_end;
    
    % Get the desired block out of the movie
    if ischar(M)
        [path, dataset] = parse_movie_name(M);
        idx_begin = [y_begin, x_begin, 1];
        num_elements = [y_end - y_begin + 1, x_end - x_begin + 1, npt];
        M_out = h5read(path, dataset, idx_begin, num_elements);
    else
        M_out = M(y_keep, x_keep, :);
    end
    % Make sure output is single
    M_out = single(M_out);
    % Replace nan pixels with zeros
    M_out = replace_nans_with_zeros(M_out);
    % Trim zero edges (e.g. due to image registration ertifacts)
    try
        [M_out, nz_top, nz_bottom, nz_left, nz_right] = ...
            remove_zero_edge_pixels(M_out);
    catch
        nz_top=0;
        nz_bottom=0;
        nz_left=0;
        nz_right=0;
    end
    
    x_keep = x_keep(nz_left+1:end-nz_right);
    y_keep = y_keep(nz_top+1:end-nz_bottom);
    fov_occupation = false(h, w);
    fov_occupation(y_keep, x_keep) = true;
    %fprintf('\t \t \t Discarding a [%d px top, %d px bottom, %d px left, %d px right] inactive movie region. \n'...
    %    ,nz_top, nz_bottom, nz_left, nz_right);
    
end
