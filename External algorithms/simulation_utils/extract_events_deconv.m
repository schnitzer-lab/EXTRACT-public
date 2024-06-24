function times = extract_events_deconv(T,sigma,tau)
    if nargin < 3 || isempty(tau)
        tau = 10;
    end

    temp_kernel = exp(-(1:5*tau)/tau);
    tr_dec = deconv([T,zeros(1,5*tau-1)],temp_kernel);
    tr_dec(tr_dec < 0 ) = 0;
    times = find(tr_dec>sigma);

end