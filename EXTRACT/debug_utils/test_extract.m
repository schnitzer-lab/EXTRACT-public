%% Generate simulated data
SNR = 1;
[h,w,t] = deal(50,50,3000);
n_cells = 50;
min_cell_radius = 7;
max_cell_radius = 12;
min_cell_dist = 5;
event_rate = 0.01;
event_tau=10;
noise_std = 0.02;
peak_SNR=SNR*sqrt(2/event_rate/event_tau);
[M,F_ground,T_ground,spikes_ground] = simulate_data([h,w,t],n_cells,...
[min_cell_radius,max_cell_radius],min_cell_dist,event_rate,...
event_tau,peak_SNR,noise_std, 0);
F_ground = reshape(F_ground,h*w,size(T_ground,1));
% M = reshape(M,h*w,t);
M = single(M);
%% Setup config
[h, w, t] = size(M);
config = [];
config.kappa_std_ratio=1;
config.init_kappa_std_ratio=1;
config.plot_loss=1;
config.verbose = 2;
config.avg_cell_radius = 5;
config.high2low_brightness_ratio = 15;
config.max_iter = 0;

%%  Run extract
M_extract = M;
profile off;
profile on;
output = extractor(M_extract, config);
% profile viewer;
profile off;
[d1, d2, d3] = size(output.spatial_weights);
F1 = reshape(output.spatial_weights,d1*d2, d3);
T1 = output.temporal_weights';

clf;
imagesc(max(M_extract, [], 3), [0, 0.2]);
axis image;
colormap bone;
% plot_cells_overlay(reshape(F_ground, h, w, size(F_ground, 2)), 'g')
plot_cells_overlay(output.spatial_weights);

%% save to rec for classification
filters = double(output.spatial_weights);
traces = output.temporal_weights;
info.num_pairs = size(traces, 2);
info.type = 'none';
save('rec_extract', 'filters', 'traces', 'info');
ds = DaySummary('', '');


%% Run initialization
M_init = M;

[S, T, S_trash, T_trash, maxes] = cw_EXTRACT(M_init, config, F_ground);

figure(1);
imagesc(max(M_init, [], 3));
axis image;
colormap bone;
hold on
scatter(maxes(2,:),maxes(1,:))
hold off
plot_cells_overlay(reshape(F_ground, h, w, size(F_ground, 2)), 'g');
plot_cells_overlay(reshape(S, h, w, size(S, 2)), 'w');

