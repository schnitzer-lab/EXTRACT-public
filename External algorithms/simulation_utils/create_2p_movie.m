function create_2p_movie(opts_2p,name)
    [M,S_ground,T_ground,spikes_ground,amps_ground] = simulate_data([opts_2p.ns,opts_2p.ns,opts_2p.nt], ...
        opts_2p.n_cell,opts_2p.cell_radius,opts_2p.min_cell_dist,opts_2p.event_rate,opts_2p.event_tau, ...
        opts_2p.cell_snr, opts_2p.noise_std, opts_2p.ratio_corr_noise, opts_2p.exp_trace_flag, ...
        opts_2p.spike_var_range,opts_2p.spike_sync_prob,opts_2p.refractory_period);

    M = M+1;
    
    max_im = max(M,[],3);
    
    mov_2p.S = S_ground;
    mov_2p.T = T_ground;
    mov_2p.spikes = spikes_ground;
    mov_2p.amplitudes = amps_ground;
    mov_2p.max_im = max_im;
    save([name '.mat'],'mov_2p','opts_2p','-v7.3');
    h5create([name '.h5'],'/mov',[opts_2p.ns,opts_2p.ns,opts_2p.nt],'Datatype','single');
    h5write([name '.h5'],'/mov',single(M));
end