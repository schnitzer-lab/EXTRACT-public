# External wrappers 

Before running EXTRACT, it is a pre-requisite to correct any type of motion in the movie. Moreover, as long as the experimental conditions permit, downsampling the movie before running EXTRACT tends to decrease the overall runtimes and increase the effectiveness of the algorithm. 

For motion correction, we have written a wrapper around the [NoRMCorre](https://github.com/flatironinstitute/NoRMCorre) pipeline. Please download the source files and keep in MATLAB path if you wish to utilize our wrapper. We also provide a template script in the folder "Template scripts" for preprocessing the movie before running EXTRACT.
