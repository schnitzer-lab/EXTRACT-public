function mask = get_arbitrary_mask(M)
    if ischar(M) || iscell(M)
        [path, dataset] = parse_movie_name(M);
        [h, w, t] = get_movie_size(M);
        M_out = h5read(path, dataset, [1,1,1], [h,w,min(100,t)]);
        im = max(M_out, [], 3);
        clear M_out
    else
        im = max(M, [], 3);
    end
    
    c_lim = quantile(im(:),[0 0.9]);
    imshow(im,c_lim);
    roi = drawassisted();
    mask = createMask(roi);

end