function [recall,precision,ampcor,auc] = get_simulation_results(a,output)

mov_2p = a.mov_2p;
opts_2p = a.opts_2p;
S_ground = mov_2p.S;
T_ground = mov_2p.T;
ns = opts_2p.ns;
amps_ground = mov_2p.amplitudes;
spikes_ground = mov_2p.spikes;

S_ex = output.spatial_weights;
S_ex = reshape(S_ex,ns*ns,[]);
T_ex = output.temporal_weights';

idx_match = match_sets(S_ground,S_ex,0.5);
recall = size(idx_match,2)/size(S_ground,2);
precision = size(idx_match,2)/size(S_ex,2);

[~,~,cors_ex] = calculate_matching_amplitudes(spikes_ground(idx_match(1,:)),...
            T_ground(idx_match(1,:),:),T_ex(idx_match(2,:),:));

ampcor = mean(cors_ex(~isnan(cors_ex)));

roc= compute_ROC_curve(spikes_ground(idx_match(1,:)),T_ex(idx_match(2,:),:),1);
[auc] = compute_AUC(roc);
end