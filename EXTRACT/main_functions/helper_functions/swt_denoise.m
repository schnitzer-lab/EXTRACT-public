function sd = swt_denoise(s, strength)
    if nargin < 2 || isempty(strength)
        strength = 1;
    end
    
    % Ensure s is a row vector
    if size(s, 1) > 1
        if size(s, 2) > 1
            error('Input to swt_denoise() must be a vector.');
        else
            s = s';
        end
    end
    
    wavelet = 'db1';
    delete_upto = strength;
    level = delete_upto;
    orig_len = length(s);
    
    % Level has to be multiple of min_len
    min_len = 2^level;
    new_len = min_len * ceil(orig_len / min_len);
    n_pad = new_len - orig_len;
    s = [s, zeros(1, n_pad)];
    [swa,swd] = swt(s,level,wavelet); 
    % Hard thresholding of detail coefficients
    swd(1:delete_upto, :) = 0;
    sd = iswt(swa, swd, wavelet);
    sd = sd(1:orig_len);
end