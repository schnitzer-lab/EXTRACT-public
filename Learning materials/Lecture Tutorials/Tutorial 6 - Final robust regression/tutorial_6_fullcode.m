EXTRACT_setup;

load('example.mat'); 
M = M-1; % ground truth movie with F = 0;
S = S_ground(:,1:15);

config=[];
config = get_defaults(config); 
config.avg_cell_radius=7;
config.S_init = S;
config.preprocess = 0; %using a preprocessed movie
config.F_per_pixel = ones(50,50); % F values are all one
config.trace_output_option='no_constraint';
config.use_gpu=0; 
config.regression_only = 1;
output_rb=extractor(M,config);
T_ex = output_rb.temporal_weights';
config.trace_output_option='least_squares';
output_ls=extractor(M,config);
T_ls = output_ls.temporal_weights';

%% Plot the results

color_extract = [0 0.4470 0.7410];
color_gt      = [144 103 167]./255;
color_l2 = [ 0.8500    0.3250    0.0980];
plot_stacked_traces_double(T_ground(1:15,:), ...
    T_ex,1,{color_gt,color_extract},[],[],{5,3});
plot_stacked_traces_double(T_ground(1:15,:), ...
    T_ls,1,{color_gt,color_l2},[],[],{5,3});