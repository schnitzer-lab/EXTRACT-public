%% *MatNWB Setup*
% Start by setting up your MATLAB workspace. The code below clones the
% MatNWB repo to the current directory and adds the folder ontaining the 
% MatNWB package to the MATLAB search path. MatNWB works by automatically 
% creating API classes based on a defined schema. Running the generateCore() function
% generates these classes for the lastest schema version.

!git clone https://github.com/NeurodataWithoutBorders/matnwb.git
cd ../matnwb
addpath(genpath(pwd));
generateCore();
%% *Load in Image Files*
% The extractor.m function function requires two inputs

%  1) An image stack with dimensions [rows, columns, frames]
%  2) A config strcuture with the parameters for the EXTRACT algorithm


% You can read in an nwb file with the nwbRead function from MatNWB. The code 
% below reads in a file downloaded from this DANDIset https://dandiarchive.org/dandiset/000054/0.210819.1547 
%For this file, the raw images are located as a DataStub within 
% the TwoPhotonSeries object. In MatNWB, the data is read "lazily". This means 
% that, instead of reading the entire dataset into memory, you have the option 
% of reading just a subset of the data stored on disk. The code below reads into 
% memory only the first 2,000 frames of the data. You can refer to the MatNWB 
% ophys tutorial to learn more about the structure and contents of NWB files. 

% Load File (change to your own file location)
inputFilePath = '/Users/cesar/Documents/DANDI_files/sub-F1_ses-20190407T210000_behavior+ophys.nwb';
nwb = nwbRead(inputFilePath);
% Load in image stack
image_stack = nwb.acquisition.get('TwoPhotonSeries').data.internal.stub(:, :, 1:2000);

%% 
% The code belows creates a simple config structure with default parameters. 
% See the 'Starting code' EXTRACT tutorial for further information about the various 
% parameters used by the EXTRACT package.

% Define config structure with default arguments
config = [];
config = get_defaults(config); %calls the defaults
config.avg_cell_radius = 7; % Set average cell radius estimate (REQUIRED)
config.prepocess = true;% preprocess data before EXTRACT
config.use_gpu = false;% assuming no GPU available

%% *Run EXTRACT*
% Finally, you can run EXTRACT on the loaded image stack with the parameters 
% specified in the config structure. The output structure contains the spatial 
% and temporal weights for each ROI. 

output = extractor(image_stack, config);% Perform EXTRACTion: