%% Create the movie
clear
clc
if ~isfile('Example_1p_movie.h5')
    [opts_2p,opts_back] = get_1p_defaults();
    opts_2p.ns = 100;
    opts_2p.n_cell = 100;
    opts_back.ns = 100;
    opts_back.n_cell = 20;
    opts_back.cell_radius = [20,40];
    rng(1)
    create_1p_movie(opts_2p,opts_back,'Example_1p_movie');
end


%% h5read function and watching the preprocessed movie

M = h5read('Example_1p_movie.h5','/mov');
view_movie(M)
max_im = max(M,[],3);

%% Highpass in spatial patches


%% Global preprocessing


