function M_out = temporal_matched_filter(M)
% Matched filter
% M = 2-D matrix
% returns M_out: matched filter output

tau = estimate_tau(M)/2;
h_matched = exp(-(1:5*tau)/tau);
h_matched = fliplr(h_matched);
h_matched = h_matched/norm(h_matched);
M_out = conv2(1,h_matched,M,'same');
end