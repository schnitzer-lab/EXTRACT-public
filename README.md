# EXTRACT
EXTRACT is a tractable and robust automated cell extraction tool for calcium imaging.

## Running EXTRACT
Call the function 'extractor' as:

`output = extractor(M,config)`.

### Inputs:
`M`: either an existing 3-D movie matrix in the workspace, or a string that specifies an HDF5 path to a 3-D movie matrix.
If M is a string, it must be in the following format: `filepath:dataset`.

`config:` a struct whose fields define the various parameters used for signal extraction (read on for details on `config`).

### Output:
The output is a struct with the following fields:

* `spatial_weights`: `[movie_height x movie_width x number_of_cells_found]` array of inferred spatial images of the cells found.

* `temporal_weights`: `[number_of_movie_frames x number_of_cells_found]` array of inferred calcium traces belonging to each cell.

* `info`: A struct that contains some algorithm statistics.

* `config`: The full `config` struct used by the algorithm (including the defaults).

Important fields of `config`:

* `avg_cell_radius` (Required): Radius estimate for an average cell in the movie. 
It does not have to be precise; however, setting it to a significantly larger or lower value will impair performance. 
* `cellfind_min_snr`: Minimum peak SNR ( defined as peak value / noise std.) value for an object to be considered as a cell. Default: `5`.

Other `config` fields:

* `dendrite_aware`: Boolean flag, set it to `true` if dendrites exist in the movie & are desired in the output. Default: `false`.
* `crop_cicrcular`: For microendoscopic movies, set it to `true` for automatically cropping out the region outside the circular imaging region. Default: `false`.
* `preprocess`: EXTRACT does preprocessing steps such as taking dF/F, highpass filtering for suppressing excessive background, and circular masking for endoscopic movies. Set to `false` to skip all preprocessing. Default: `true`.
* `cellfind_filter_type`: Type of the spatial smoothing filter used for cell finding. Options: `'butter'` (IIR butterworth filter), `'gauss'` (FIR filter with a gaussian kernel), `'wiener'` (wiener filter), `'none'` (no filtering). Default: `'butter'`.
* `temporal_denoising`: Boolean flag that determines whether to apply temporal wavelet denoising. This functionality is experimental; expect it to increase runtime considerably if the input movie has >10K frames and hase larger field of view than 250x250 pixels. Default: `false`.
* `remove_stationary_background`. Boolean flag that determines whether to subtract the (spatially) stationary background (largest spatiotemporal mode of the movie matrix). Default: `true`.
* `smoothing_ratio_x2y`: If the movie contains mainly objects that are elongated in one dimension (e.g. dendrites), this parameter is useful for more smoothing in either x or y dimension. Default: `1`.
* `use_gpu:` Boolean flag that determines if GPU should be used. This is automatically set to zero if a GPU was not found with enough memory.Default: `true`.
* `multi_gpu:` Boolean flag for parralel processing of different movie partitions on multiple GPUs (if applicable) in the GPU mode. Default: `false`.
* `parallel_cpu:` Boolean flag for parallel processing of different movie partitions in the CPU mode. This flag is only effective when `use_gpu = 0`. Default: `false`.
* `num_parallel_cpu_workers:` When `config.parallel_cpu = 1`, this parameter can be used to set the desired number of CPU workers. Default is # of available cores to Matlab - 1 (minus 1 is for leaving compute room for other tasks).
* `cellfind_numpix_threshold`: During cell finding, objects with an area < `cellfind_numpix_threshold` are discarded. Default: `9`.
* `downsample_time_by`, `downsample_space_by`: Downsampling factors. Set to `'auto'` for automatic downsampling factors based on avg cell radius and avg calcium event time constant. Defaults: `1` & `1`.
* `num_partitions_x`, `num_partitions_y` : User specified number of movie partitions in x and y dimensions. Defaults: `1` & `1`.
* `spatial_highpass_cutoff`, `spatial_lowpass_cutoff`: These cutoffs determine the strength of butterworth spatial filtering of the movie (higher values = more lenient filtering), and are relative to the average cell radius. Defaults: `5` & `2`.
* `adaptive_kappa`: If `true`, then during cell finding, the robust esimation loss will adaptively set its robustness parameter. Default: `false`.
* `smooth_T` : If set to `true`, calculated traces are smoothed using median filtering. Default : `false`.
* `smooth_S` : If set to `true`, calculated images are smoothed using a 2-D gaussian filter. Default : `false`.
* `verbose`: Log is emitted from the console output when set to `1`, set to `0` to suppress output. Default: `1`.
* `min_radius_after_downsampling`: When `downsample_space_by= 'auto'`, this determines the spatial downsampling factor by setting a minimum avg radius after downsampling. Default: `5`.
* `min_tau_after_downsampling`: When `downsample_time_by='auto'`, this determines the temporal downsampling factor by setting a minimum event tau after downsampling. Default: `5`.
* `reestimate_S_if_downsampled`: When set to `true`, images are re-estimated from full movie at the end. When `false`, images are upsampled by interpolation. `reestimate_S_if_downsampled=true` is not recommended as precise shape of cell images are typically not essential, and re-estimation from full movie is costly.
* `medfilt_outlier_pixels`: Flag that determines whether outlier pixels in the movie should be replaced with their neighborhood median. Default: `false`.
* `remove_duplicate_cells`: For movies processed in multiple partitions, this flag controls duplicate removal in the overlap regions. Default: `true`.
* `kappa_std_ratio`. Kappa will be set to this times the noise std. Lower values introduce more robustness at the expense of an underestimation bias in `F` and `T` (especially in the low SNR regime). Default : `1`.
* `init_with_gaussian`: If true, then during cell finding, each cell is initialized with a gaussian shape prior to robust estimation. If false, then initialization is done with a correlation image (preferred for movies with dendrites). Default: `true`.
* `max_iter` : Maximum number of alternating estimation iterations. Default : `6`.
* `max_iter_F`,`max_iter_T` : Maximum number of iterations for `F` and `T` estimation steps. Default: `100` and `50`.
* `TOL_main` : If the relative change in the main objective function between 2 consecutive alternating minimization steps is less than this, cell extraction is terminated. Default: `1e-6`.
* `TOL_sub` : If the 1-step relative change in the objective within each `T` and `F` optimization is less than this, the respective optimization is terminated. Default: `1e-6`.
* `T_dup_corr_thresh`,`F_dup_corr_thresh` : Through alternating estimation, cells that have higher trace correlation than `T_dup_corr_thresh` and higher image correlation than `F_dup_corr_thresh` are eliminated. Defaults:  `0.9` & `0.95`.
* `temporal_corrupt_thresh` , `spat_corrupt_thresh` : Spatial & temporal corruption indices (normalized to [`0`, `1`]) is calculated at each step of the alternating minimization routine. Images / traces that have an index higher than these are eliminated. Defaults : `0.7` & `0.5`.
* `plot_loss`: When set to `true`, empirical risk is plotted against iterations during alternating estimation. Default: `false`.
* `init_kappa_std_ratio`: Kappa will be set to this times the noise std for the component-wise EXTRACT during initialization. Default: `1`.
* `cellfind_maxnum_iters`: Maximum number of intiialization iterations. Default: `1000`.
* `compact_output`: If set to `true`, then the output will not include bad components that were found but then eliminated. This usually reduces the memory used by the output struct substantially. Default: `true`.
* `S_init`: Optionally, provide cell images in `config.S_init` as a 2-D matrix (with the size of the first dimension equal to movie height x movie width), and the algorithm will use these as the initial set of cells, skipping its native initialization. Default: empty array.
* `l1_penalty_factor`: A numeric in range `[0, 1]` which determines the strength of l1 regularization penalty to be applied when estimating the temporal components. The penalty is applied only to cells that overlap in space and whose temoral components are correlated. Use larger values if spurious cells are observed in the vicinity of high SNR cells. Default: `0.5`.
