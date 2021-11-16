%% WRITE TO NWB TUTORIAL
% This tutorial covers two approaches for writing EXTRACT output data to
% file:
%   1. Writing data to a new NWB file
%   2. Writing data to an existing NWB file
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

%% *NWB Extension Setup*
% The helper function below uses an extension of the NWB:N format to store
% the configuration options and output of the EXTRACT pipeline. The code
% below clones the github repo defining this extension and generates the
% MATLAB code implementing the extension. 

!git clone https://github.com/catalystneuro/ndx-extract.git
generateExtension('ndx-extract/spec/ndx-EXTRACT.namespace.yaml');

%NOTE: This tutorial assumes you have an output variable in your workspace
%after running the EXTRACT pipeline. See the read_in_NWB.m tutorial  in the 
%same folder or the '1. Starting code' tutorial for details on how to run
%the EXTRACT pipeline.

%% Approach 1. Writing data to a new NWB file
%% Building options Structure
% %
options = struct();
% define propperties of NWB to which to write the EXTRACT output.
options.nwb_file.session_start_time =  '2021-01-01 00:00:00'; % change to your own session start time
%options.nwb_file.identifier = 'test_file';% Defaults to a UUID string
options.nwb_file.session_description = 'EXTRACT_output_tutorial';

% Creating a valid NWB file requires definition of an ImagingPlane object
% and its dependencies. The below group of parameters defines the necessary
% properties. If these are not provided, default values will be used
options.imaging_plane.name = 'imaging_plane'; %Defaults to ImagingPlane
% options.device_name = 'microscope'; %Defaults to 'microscope'
% options.optical_channel.description = 'optical channel';% Defaults to 'optical channel'
options.optical_channel.emission_lambda = 500;% Defaults to NaN
options.imaging_plane.description = '250 um below surface';% Defaults to 'imaging plane description'
options.imaging_plane.excitation_lambda = 600;% Defaults to NaN
options.imaging_plane.imaging_rate = 15;% Defaults to NaN
options.imaging_plane.indicator = 'GCaMP';% Defaults to 'unknown'
options.imaging_plane.location = 'brain location';% Defaults to 'unknown'

% Other parameters
% name of processing  module with optical physiology data. Defaults to 'ophys'
options.processing_module_name = 'ophys';
% label for of ImageSegmentation object.  Defaults to 'ImageSegmentation'
options.img_segmentation_name = 'ImageSegmentation'; 
% label for of PlaneSegmentation object. Defaults to 'PlaneSegmentation'
options.plane_segmentation_name = 'PlaneSegmentation';
% unit of ROI timeseries data. Defaults to 'n.a.'
options.timeseries_data_unit = 'n.a.';
% % timing details of ROI time series.
% % If timing is regular, need only supply starting time and sampling rate
% options.starting_time = 0; % starting time. Defaults to 0
options.sampling_rate = 15; % sampling rate. Defaults to NaN
% % If timing is irregular, supply timestamps instead
% options.timestamps = 0:1999;
%% EXTRACT Output to NwbFile Object
output_nwb = EXTRACT_output_to_nwb(output, options);
%% Export NWB file
nwbExport(output_nwb, 'EXTRACT_output.nwb');
%% Approach 2. Writing data to an existing NWB file
% %% Building options Structure
% %
% % Writing to an existing NWB file is very similar to the above. Simply
% % supply an existing NwbFile object in the 'nwb_file' field.
options = struct();
% % NWB file to which to write the EXTRACT output.
options.nwb_file = nwb;
% % Additionally, you can simply supply the identifier string of the TwoPhotonSeries
% % object containing the data fed into the EXTRACT pipeline. The timing
% % details of the ROI time series will be extracted with this information
% % along with the relevant ImagingPlane object.
options.source_acquisition = 'TwoPhotonSeries';
% % label for of ImageSegmentation object.  Defaults to 'ImageSegmentation'
% options.img_segmentation_name = 'ImageSegmentation'; 
% % label for of PlaneSegmentation object. Defaults to 'PlaneSegmentation'
% options.plane_segmentation_name = 'PlaneSegmentation';
% % unit of ROI timeseries data. Defaults to 'n.a.'
options.timeseries_data_unit = 'n.a.';
%% EXTRACT Output to NwbFile Object
output_nwb = EXTRACT_output_to_nwb(output, options);
%% Export NWB file
% % When appending to an NWB file that was read in from disk, you MUST use the same 
% % file path. Otherwise, the nwbExport function will produce an error. 
inputFilePath = '/Users/cesar/Documents/DANDI_files/sub-F1_ses-20190407T210000_behavior+ophys.nwb';
nwbExport(output_nwb, inputFilePath);

