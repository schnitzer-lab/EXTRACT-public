%% Welcome to the EXTRACT tutorial! Written by Fatih Dinc, 06/23/2024
clear;
clc
EXTRACT_setup;
load(fullfile(whichEXTRACT(),"Learning materials",...
    "Sample data","example.mat")); 
config=[];
config = get_defaults(config); 
config.avg_cell_radius=7;
config.trace_output_option='no_constraint';
config.num_partitions_x=1;
config.num_partitions_y=1; 
config.use_gpu=0; 
config.max_iter = 10; 
config.cellfind_min_snr=0;
config.thresholds.T_min_snr=10;
output=extractor(M,config);

%% Matching to ground truth and plotting the results
[h,w,k]=size(full(output.spatial_weights));
S_ex=reshape(full(output.spatial_weights),h*w,k);
idx_match = match_sets(S_ex, S_ground,0.8); 
T_ex = output.temporal_weights';


color_extract = [0 0.4470 0.7410];
color_gt      = [144 103 167]./255;
color_l2 = [1,0.5,1];
plot_stacked_traces_double(T_ground(idx_match(2,:),:), ...
    T_ex(idx_match(1,:),:),1,{color_gt,color_extract},[],[],{5,3});
exportgraphics(gcf,'FigA.eps','ContentType','vector')

ims_ex = reshape(S_ex,h,w,[]);
ims_g = reshape(S_ground,h,w,[]);
max_im = max(M,[],3);

plot_simulated_cellmap(ims_g, ...
    max_im,ims_ex(:,:,idx_match(1,:)),color_extract,color_l2)

exportgraphics(gcf,'FigB.eps','ContentType','vector')
%%
thr_all = linspace(2,20,10);
precision = zeros(1,size(thr_all,2));
recall    = zeros(1,size(thr_all,2));
for i = 1:size(thr_all,2)
    config.thresholds.T_min_snr=thr_all(i);
    config.verbose = 0;
    output=extractor(M,config);
    S_ex=reshape(full(output.spatial_weights),h*w,[]);
    idx_match = match_sets(S_ex, S_ground,0.8); 
    precision(i) = size(idx_match,2)/size(S_ex,2);
    recall(i) = size(idx_match,2)/size(S_ground,2);
    fprintf('%d finished.\n',i);
end


%
figure
plot(thr_all,precision,'LineWidth',3)
hold on
plot(thr_all,recall,'LineWidth',3)
legend('Precision','Recall')
set_common_gca_props
exportgraphics(gcf,'FigC.eps','ContentType','vector')


function set_common_gca_props
ax = gca;
ax.XAxis.FontSize = 15;
ax.YAxis.FontSize = 15;
ax.Color = 'none';
ax.LineWidth = 1.5;
ax.TickLength = [0.03, 0.03];
end
