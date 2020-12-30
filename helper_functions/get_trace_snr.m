function T_snr = get_trace_snr(T, do_medfilt)

if nargin < 2 || isempty(do_medfilt)
    do_medfilt = true;
end

noise = estimate_noise_std(T) * sqrt(2);
if do_medfilt
    T = medfilt1(T, 3, [], 2);
end
signal = max(T, [], 2);
T_snr = signal ./ noise;

end