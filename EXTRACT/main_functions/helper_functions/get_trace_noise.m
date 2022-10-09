function sn = get_trace_noise(Y)
    Y = Y';
    range_ff = [.25, .5];
    [psdx, ff] = pwelch(double(Y), [],[],[], 1);
    indf = and(ff>=range_ff(1), ff<=range_ff(2));
    sn = sqrt(exp(mean(log(psdx(indf,:)/2))))'; 
end

% 
%  range_ff = [.2, .5];
% [psdx, ff] = pwelch(double(T'), [],[],[], 1);
% indf = and(ff>=range_ff(1), ff<=range_ff(2));
% sn = sqrt(exp(mean(log(psdx(indf,:)/2))))';
% ss = sqrt(exp(mean(log(psdx(~indf,:)/2))))';
% % 

range_ff = [.2, .5];
num_cells = size(T, 1);
ss = zeros(1, num_cells);
sn = zeros(1, num_cells);
rat = zeros(1, num_cells);
for i = 1:num_cells
    t = T(i, :);
%     t(t<=0) = [];
    [psdx, ff] = pwelch(double(t'), [],[],[], 1);
    indf = and(ff>=range_ff(1), ff<=range_ff(2));
    sn(i) = sqrt(exp(mean(log(psdx(indf,:)/2))))';
    ss(i) = sqrt(exp(mean(log(psdx(~indf,:)/2))))';
    rat(i) = sqrt(sum(psdx(indf, :))/sum(psdx(~indf, :)));
end


max_vals = max(medfilt1(T, 3, [], 2), [], 2)';
trace_snr =max_vals./sn/sqrt(2);
plot(trace_snr);
% [~,idx_ordered] = sort(trace_snr, 'descend');
% max_vals = max_vals(idx_ordered);
% plot(max_vals*430);
% hold on;
% plot(trace_snr(idx_ordered));
% hold off;
% 
% for i = 1:length(idx_ordered)
%     idx = idx_ordered(i);
%     plot(T(idx, :));
%     title(trace_snr(idx));
%     pause;
% end
% 
% idx = find((trace_snr'<2) & (max(T, [], 2)>0.02);