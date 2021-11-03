%% WRITE TO NWB TUTORIAL
% This tutorial covers two approaches for writing EXTRACT output data to
% file:
%   1. Writing data to a new NWB file
%   2. Writing data to an existing NWB file (TODO)
%% Approaching 1. Writing data to a new NWB file
%% Building options Structure
%
options = struct();
% NWB file to which to write the EXTRACT output.  If none provided a new file 
% will be generated. It's best practice to create NwbFile with proper
% session start time.
options.nwb_file = NwbFile( ...
    'session_start_time', '2021-01-01 00:00:00', ...
    'identifier', 'ident1', ...
    'session_description', 'EXTRACT_output_tutorial' ...
    );
% name of processing  module with optical physiology data. Defaults to 'ophys'
options.processing_module_name = 'ophys'; 
% label for of ImageSegmentation object.  Defaults to 'ImageSegmentation'
options.img_segmentation_name = 'ImageSegmentation'; 
% label for of PlaneSegmentation object. Defaults to 'PlaneSegmentation'
options.plane_segmentation_name = 'PlaneSegmentation';
% unit of ROI timeseries data. Defaults to 'n.a.'
options.data_unit = 'n.a.';
% timing details of ROI time series. REQUIRED for new NWB file.
options.starting_time = 0; % starting time
options.starting_time_rate = 15; %sampling rate
%% EXTRACT Output to NwbFile Object
% Append output data to NWB file
output_nwb = EXTRACT_output_to_nwb(output, options);

%% Export NWB file
nwbExport(output_nwb, 'EXTRACT_output.nwb');
%% 1. Writing data to an existing NWB file (TODO)
% name of TwoPhotonSeries object, containing raw image data 
%options.source_acquisition = 'TwoPhotonSeries';