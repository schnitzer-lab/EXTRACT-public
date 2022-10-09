function [S_all, T_all] = combine_all_traces_and_images(output)

S_bad = output.info.summary.S_bad;
T_bad = output.info.summary.T_bad;
T = output.temporal_weights';
S = output.spatial_weights;
[h, w, k] = size(S);
S = reshape(S, h*w, k);
S_all = [S,S_bad];
T_all = [T;T_bad];