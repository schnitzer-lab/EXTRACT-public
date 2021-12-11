%% Welcome to the EXTRACT tutorial! Written by Fatih Dinc, 03/02/2021
%perform cell extraction
clear;
load('example.mat'); %contains a movie M, ground truth cell maps (S_ground) and traces (T_ground)
config=[];
config = get_defaults(config); %calls the defaults

% Essentials, without these EXTRACT will give an error:
config.avg_cell_radius=7; %Average cell radius is 7.


%Optionals, but strongly advised to handpick:
%Movie is small enough that EXTRACT will not automatically partition this,
%but still a good idea to keep these in sight!
config.trace_output_option='raw'; % Choose 'nonneg' for non-negative Ca2+ traces, 'raw' for raw ones!
config.num_partitions_x=1;
config.num_partitions_y=1; 
config.cellfind_filter_type='none'; % The movie is clean enough, no need for lowpass filtering
config.verbose=2; %Keeping verbose=2 gives insight into the EXTRACTion process, always advised to keep 2
config.spatial_highpass_cutoff=inf; % no need for highpass filtering
config.remove_background=0; %no need for background removal


% Optionals whose defaults exist:
config.use_gpu=0; % This is a small dataset, will be fast on cpu anyways.
config.max_iter = 10; % 10 is a good number for this dataset
config.adaptive_kappa = 1;% Adaptive kappa is on for this movie. For an actual movie, keeping it off
% may be beneficial depending on the noise levels.
config.cellfind_min_snr=0.5;% Default snr is 1, lower this (never less than 0) to increase cell count at the expense of more spurious cells!
config.thresholds.T_min_snr=5;

config.visualize_cellfinding=1;

% Perform EXTRACTion:
output=extractor(M,config);

%% Matching ground truth to EXTRACTed signals
[h,w,k]=size(full(output.spatial_weights));
S_ex=reshape(full(output.spatial_weights),h*w,k);
idx_match = match_sets(S_ex, S_ground); %this is a very useful helper function, use this as you need!

T_ex = output.temporal_weights';
%% Perform multivariate linear regression for comparison
M_res=reshape(M,2500,2000);
X=mean(M_res,2);
M_res=(M_res-X)./X; %perform dfof
S=S_ex;
T_est=(S'*S)^(-1)*S'*M_res;
% Since this movie does not contain unfound cells or neuropils, this will
% be close to ground truth and EXTRACT outputs!
%%
pick=20;
plot(T_ex(idx_match(1,pick),:));
hold on
plot(T_ground(idx_match(2,pick),:))
hold on
plot(T_est(idx_match(1,pick),:))

