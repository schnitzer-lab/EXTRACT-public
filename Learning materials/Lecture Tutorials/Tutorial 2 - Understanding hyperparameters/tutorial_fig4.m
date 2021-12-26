%% Welcome to the EXTRACT tutorial! Written by Fatih Dinc, 03/02/2021
%perform cell extraction
clear;
M = single(hdf5read('Fig4_example.h5','/data'));
%%
config=[];
config = get_defaults(config); %calls the defaults

% Essentials, without these EXTRACT will give an error:
config.avg_cell_radius=6; 

% The movie is small, one partition should be enough!
config.num_partitions_x=1;
config.num_partitions_y=1; 

% All the rest is to be optimized, which is the purpose of this tutorial!

output=extractor(M,config);


%% Check quality
figure, imshow(max(M,[],3),[0 50]);
plot_cells_overlay(output.spatial_weights,[1,0,0],[])
%% Check movie
view_movie(M, 'ims',output.spatial_weights,'im_colors',[1, 0.5, 0])

