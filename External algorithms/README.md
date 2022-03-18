# External wrappers 

Before running EXTRACT, it is a pre-requisite to correct any type of motion in the movie. Moreover, as long as the experimental conditions permit, downsampling the movie before running EXTRACT tends to decrease the overall runtimes and increase the effectiveness of the algorithm. 

To aid with motion correction, we have written a wrapper around the published [NoRMCorre](https://github.com/flatironinstitute/NoRMCorre) motion correction algorithm. Please download the source files and keep them in MATLAB path if you wish to utilize our wrapper, which incorporates elements from EXTRACT helper functions to further enhance the motion correction process. We also provide a template script in the folder "Template scripts" for preprocessing calcium movies (motion correction, downsampling etc.). 
