# Extract version 1.0

Extract is a  <ins>t</ins>ractable and <ins>r</ins>obust  <ins>a</ins>utomated <ins>c</ins>ell extraction  <ins>t</ins>ool for calcium imaging, which *extracts* the activities of cells as time series from both one-photon and two-photon Ca<sup>2+</sup> imaging movies. Extract makes minimal assumptions about the data, which is the main reason behind its high robustness and superior performance. 

Its main features and the mathematical foundations behind Extract can be found in Inan et al. (2017), and a comparison with state-of-the-art methods in an upcoming pre-print. If you use Extract for your own research, please cite the Hakan et al (2017) for now. We will provide the citation details for the upcoming pre-print soon.

```Latex
@article{inan2017robust,
  title={Robust estimation of neural signals in calcium imaging},
  author={Inan, Hakan and Erdogdu, Murat A and Schnitzer, Mark},
  journal={Advances in neural information processing systems},
  volume={30},
  pages={2901--2910},
  year={2017}
}
```
<img src="https://user-images.githubusercontent.com/56279691/103445994-9e9a2780-4c8b-11eb-9693-6684cca73743.png" width="42%" align="right" alt="Extract_pipeline">

## Content

- [Installation](#installation)
- [A quick start for beginners](#a-quick-start-for-beginners)
- [Advanced aspects](#advanced-aspects)
- [Questions and comments](#questions-and-comments)
- [License](#license)
- [Planned future releases](#planned-future-releases)
- [Frequently asked questions](#frequently-asked-questions)

## Installation

It is fairly straightforward to install Extract. Simply download all the files from the repository and include them in the MATLAB path. Installation is complete. Extract makes use of various packages and toolboxes, check out the [Dependencies](#dependencies) section. An example case of running Extract after installation is provided in [Example movie extraction](#example-movie-extraction).

## A quick start for beginners

Extract algorithm has two inputs, movie and configurations (a struct), and a single output, a struct that contains the information on the extracted cell signals. In its essence, the whole extract code can be run by a single line:

`output = extractor(M,config)` 

In this quick start, we first describe the inputs, specifically the most important objects in the configuration struct (e.g. `config`). Then, we discuss the components of the output file that contain the single cell activities. Finally, we provide a code for initializing the configurations and performing extraction on an example movie.

### Inputs:
`M`: either an existing 3-D movie matrix in the workspace, or a string that specifies an HDF5 path to a 3-D movie matrix.
If M is a string, it must be in the following format: `filepath:dataset`.

`config:` a struct whose fields define the various parameters used for signal extraction (See [Configurations](#configurations) for details on `config`). For a beginner, the most relevant fields are:

- `avg_cell_radius`: Radius estimate for an average cell in the movie. It does not have to be precise; however, setting it to a significantly larger or lower value will impair performance. It needs to be set at the start for any movie. A recommended way to set this is to consider the maximum projections of the video across time and pick the radius there (see [Example movie extraction](#example-movie-extraction)).
- `num_partitions_x/num_partitions_y`: User specified number of movie partitions in x and y dimensions. Running Extract on the whole movie at once could be computationally too expensive or simply impossible. In this case, we divide the input movie into smaller parts. Heuristics suggest that the size of the smaller FOV should not be smaller than 128 pixels in any of the x/y dimensions.
- `cellfind_min_snr`: Minimum peak SNR (defined as peak value/noise std) value for an object to be considered as a cell. Increase this if you want to decrease the ratio of false-positives at the expense of losing some low SNR cells in the process.
- `use_gpu`: This needs to be 1 to run Extract on GPU, 0 to run Extract on CPU. It is preferably, time-wise, to run Extract on GPU.


Extract has a helper function that initializes the config struct to the most common configurations:
```Matlab
    config=[];
    config = get_defaults(config);
```
We will provide the complete example code below in [Example movie extraction](#example-movie-extraction) section.

### Output files

The output is a struct with four fields: `spatial_weights`, `temporal_weights`, `info` and `config`. `Config` includes the configurations used by the algorithm while `info` provides some algorithm statistics that can later become useful for an expert. For a quick start, two fields are of particular importance:

- `spatial_weights`: has the shape [movie_height x movie_width x number_of_cells_found] and is an array of inferred spatial images of the cells found. Spatial weights are particularly important for cell sorting (See [Cell sorting](#cell-sorting)), a process where the user individually inspects the cell candidates and determines whether they are actual cells by looking at the activity in the raw movie.

- `temporal_weights`: has the shape [number_of_movie_frames x number_of_cells_found] and is an array of inferred calcium traces belonging to each cell. Usually, after some pre-processing that includes cell sorting, this is the actual output of Extract that gets used for the remaining of the data analysis pipeline.

### Example movie extraction

Having described how to run the algorithm and interpret the output, we know provide a basic code that can get a first time user started quickly. 
```Matlab
%First, load the movie.
load('example.mat');

% By considering the maximum projections, pick an estimate cell radius
figure, imshow(max(M,[],3),[]);

%Initialize config
config=[];
config = get_defaults(config);

%Set some important settings
config.use_gpu=1;
config.avg_cell_radius=6;
config.num_partitions_x=1;
config.num_partitions_y=1;
config.cellfind_min_snr=5; % 5 is the default SNR

%Perform the extraction
output=extractor(M,config); 

%Perform post-processing such as cell sorting and further data analysis
```

We have included the file `example.mat` in this repository to help the reader get started with the basics of Extract.

## Advanced aspects
Here, we discuss some of the more advanced aspects of Extract. We suggest that the user first becomes familiar with the example extraction process before moving forward to the more advanced settings.


### Pre-processing

In this repository, we are introducing only one part of the complete cell extraction problem. The bigger problem includes a motion correction step, which is also required for Extract to work. There are existing algorithms for this, see the pre-print for some examples. On the other hand, Extract has a configuration to perform the usual pre-processing steps including taking dF/F, highpass filtering for suppressing excessive background, and circular masking for endoscopic movies (See [Configurations](#configurations)).

### Configurations

Here is a list of more advanced configurations:

* `dendrite_aware`: Boolean flag, set it to `true` if dendrites exist in the movie & are desired in the output. Default: `false`.
* `crop_cicrcular`: For microendoscopic movies, set it to `true` for automatically cropping out the region outside the circular imaging region. Default: `false`.
* `preprocess`: EXTRACT does preprocessing steps such as taking dF/F, highpass filtering for suppressing excessive background, and circular masking for endoscopic movies. Set to `false` to skip all preprocessing. Default: `true`.
* `cellfind_filter_type`: Type of the spatial smoothing filter used for cell finding. Options: `'butter'` (IIR butterworth filter), `'gauss'` (FIR filter with a gaussian kernel), `'wiener'` (wiener filter), `'none'` (no filtering). Default: `'butter'`.
* `temporal_denoising`: Boolean flag that determines whether to apply temporal wavelet denoising. This functionality is experimental; expect it to increase runtime considerably if the input movie has >10K frames and hase larger field of view than 250x250 pixels. Default: `false`.
* `remove_stationary_background`. Boolean flag that determines whether to subtract the (spatially) stationary background (largest spatiotemporal mode of the movie matrix). Default: `true`.
* `smoothing_ratio_x2y`: If the movie contains mainly objects that are elongated in one dimension (e.g. dendrites), this parameter is useful for more smoothing in either x or y dimension. Default: `1`.
* `multi_gpu:` Boolean flag for parralel processing of different movie partitions on multiple GPUs (if applicable) in the GPU mode. Default: `false`.
* `parallel_cpu:` Boolean flag for parallel processing of different movie partitions in the CPU mode. This flag is only effective when `use_gpu = 0`. Default: `false`.
* `num_parallel_cpu_workers:` When `config.parallel_cpu = 1`, this parameter can be used to set the desired number of CPU workers. Default is # of available cores to Matlab - 1 (minus 1 is for leaving compute room for other tasks).
* `cellfind_numpix_threshold`: During cell finding, objects with an area < `cellfind_numpix_threshold` are discarded. Default: `9`.
* `downsample_time_by`, `downsample_space_by`: Downsampling factors. Set to `'auto'` for automatic downsampling factors based on avg cell radius and avg calcium event time constant. Defaults: `1` & `1`.
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

### Cell sorting

While we are working on a semi-automated cell sorting algorithm, Extract currently does not have a cell sorting algorithm that lets the user to check the raw movie and decide whether the found cell candidates are not a false-positive. 

### Dependencies

Extract requires, at least, the following toolboxes. With future releases, there may be need for further toolboxes.


- Bioinformatics Toolbox
- Econometrics Toolbox
- Image Processing Toolbox
- Parallel Computing Toolbox 
- Signal Processing Toolbox 
- Statistics and Machine Learning Toolbox
- Wavelet Toolbox


## Questions and comments

Extract is mainly written by Hakan Inan in collaboration with many researchers in Schnitzerlab. The database is maintained by the current members of Schnitzerlab. If you have any questions or comments, after checking already existing issues and the [Frequently asked questions](#frequently-asked-questions) section, please open an issue or contact via email `extractneurons@gmail.com`.


## License

Copyright (C) 2020 Hakan Inan

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

## Planned future releases

This version of Extract is written in Matlab and will be improved over the years in terms of both speed and memory consumption. Furthermore, we plan to release a Python version in the near future. 

## Frequently asked questions



### Is Extract maintained?
Extract is regularly maintained by the current members of the Schnitzerlab. Unless this answer changes, this will be the case.

### What types of movies does Extract support?

Extract can be used for cell extraction from both one-photon and two-photon calcium imaging movies.

### I believe there are more cells in the movie then Extract finds. Why is this the case?

Extract uses a set of thresholds decreasing the time that the user needs to spend on cell sorting. If for a particular movie, the false-negative count is high, one can decrease the value of `cellfind_min_snr`.

### Extract is finding too many false-positives, what can I do to decrease it?

Following the logic of the previous question, if for a particular movie, the false-positive count is high, one can increase the value of `cellfind_min_snr`.
















