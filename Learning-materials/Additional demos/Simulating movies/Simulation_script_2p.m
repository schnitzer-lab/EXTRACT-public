%% Create the movie
clear
clc

[opts_2p] = get_2p_defaults();
opts_2p.ns = 100;
opts_2p.n_cell = 100;

if isfile('Example_2p_movie.h5')
    delete('Example_2p_movie.h5')
end
if isfile('Example_2p_movie.mat')
    delete('Example_2p_movie.mat')
end
create_2p_movie(opts_2p,'Example_2p_movie');



