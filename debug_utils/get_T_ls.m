function [T_ls, T_neuropil] =  get_T_ls(M, ims)
    [h, w, n] = size(M);
    Md = reshape(M, h*w, n);
    S = reshape(ims, h*w, size(ims, 3));
    T_ls = pinv(S) * Md;
    
    % Get neuropil activity
    S_surround = get_S_surround(S, [h, w], 0.5);
    T_neuropil = pinv(S_surround) * Md;
end
