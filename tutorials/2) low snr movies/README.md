# Running EXTRACT on low SNR movies

This tutorial provides an alternative approach for running EXTRACT on low SNR movies. The movie is courtesy of Ben Yang -Parker Lab. See Parker, J.G., Marshall, J.D., Ahanonu, B. et al. Diametric neural ensemble dynamics in parkinsonian and dyskinetic states. Nature 557, 177–182 (2018). https://doi.org/10.1038/s41586-018-0090-6 Extended Data Fig 4 for more information.

Link for the movie: https://drive.google.com/file/d/1sc7yom4LlgZ42UfwuXpuZwCWzNcy2bkZ/view?usp=sharing

For this movie, one can first run a denoising script (here titled 'run_denoising,m', fill in the blanks for this particular movie appropriately), written by Jizhou Li, to obtain a denoised movie. Running EXTRACT on the denoised movie is easier than running it on the raw one, especially since it is extremely hard to pinpoint the cells even by eye in the raw movie. Note that the most important parameters to change for this type of low SNR movies are config.threshold.T_min_snr and config.cellfind_min_snr. The lowest suggested value for the former is 3, whereas for the latter is 0. For this movie, setting trace snr to 3.5 and cellfind snr to 0 would suffice for the raw version, whereas for the denoised version one can set the trace snr to 4. Try out different values to get a feeling for how to navigate hyperparameters for low SNR movies and as always, if you have any questions, feel free to reach out!

EXTRACT Team




