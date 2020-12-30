function M_out = replace_nans_with_zeros(M)
% Replace NaNs with zeros
%   M: input array
% Returns
%   M_out = output array with nans replaced with zeros
    nans = isnan(M);
    if sum(nans(:))>0
        M_out = M;
        M_out(nans) = 0 ;
    else
        M_out = M;
    end
end