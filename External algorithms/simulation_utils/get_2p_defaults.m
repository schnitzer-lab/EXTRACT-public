function opts_2p = get_2p_defaults()
    opts_2p = {};
    opts_2p.ns = 250;
    opts_2p.nt = 5000;
    opts_2p.n_cell = 600;
    opts_2p.cell_radius = [7,9];
    opts_2p.min_cell_dist = 4;
    opts_2p.event_rate = 1/100; % on average one spike per 100 frame
    opts_2p.event_tau = 10; % 10 frame / 1s decay time
    opts_2p.cell_snr = 4; 
    opts_2p.noise_std = 0.02;
    opts_2p.ratio_corr_noise = 0.05;
    opts_2p.exp_trace_flag = 1;
    opts_2p.spike_var_range = 0.3;
    opts_2p.spike_sync_prob = 0;
    opts_2p.refractory_period = 1;
end