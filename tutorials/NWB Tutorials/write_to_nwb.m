%% WRITE TO NWB TUTORIAL
% This tutorial covers two approaches for writing EXTRACT output data to
% file:
%   1. Writing data to a new NWB file
%   2. Writing data to an existing NWB file
%% Approach 1. Writing data to a new NWB file
%% Building options Structure
% %
options = struct();
% NWB file to which to write the EXTRACT output.
options.nwb_file = NwbFile( ...
    'session_start_time', '2021-01-01 00:00:00', ... % change to your own session start time
    'identifier', char(java.util.UUID.randomUUID.toString), ... % UUID string
    'session_description', 'EXTRACT_output_tutorial' ...
);
% % Include some some necessary information in NWB file. If missing, the
% % helper function will create nessary objects with non-informative values)
optical_channel = types.core.OpticalChannel( ...
    'description', 'optical channel', ...
    'emission_lambda', 500. ...
);
device_name = 'microscope';
device_obj = types.core.Device();
options.nwb_file.general_devices.set(device_name, device_obj);
imaging_plane = types.core.ImagingPlane( ...
    'optical_channel', optical_channel, ...
    'description', 'imaging plane description', ...
    'device', device_obj, ...
    'excitation_lambda', 600., ...
    'imaging_rate', 5., ...
    'indicator', 'GCaMP', ...
    'location', 'brain location', ...
    'reference_frame', 'A frame to refer to' ...
 );
% include imaging plane name in options structure
options.imaging_plane_name = 'imaging_plane';
options.nwb_file.general_optophysiology.set(options.imaging_plane_name, imaging_plane);

% name of processing  module with optical physiology data. Defaults to 'ophys'
% options.processing_module_name = 'ophys';
% label for of ImageSegmentation object.  Defaults to 'ImageSegmentation'
% options.img_segmentation_name = 'ImageSegmentation'; 
% label for of PlaneSegmentation object. Defaults to 'PlaneSegmentation'
% options.plane_segmentation_name = 'PlaneSegmentation';
% unit of ROI timeseries data. Defaults to 'n.a.'
% options.data_unit = 'n.a.';
% timing details of ROI time series.
% If timing is regular, need only supply starting time and sampling rate
% options.starting_time = 0; % starting time. Defaults to 0
options.sampling_rate = 15; % sampling rate. Defaults to NaN
% If timing is irregular, supply timestamps instead
% options.timestamps = 0:1999;
%% EXTRACT Output to NwbFile Object
% Append output data to NWB file
output_nwb = EXTRACT_output_to_nwb(output, options);
%% Export NWB file
nwbExport(output_nwb, 'EXTRACT_output.nwb');
%% Approach 2. Writing data to an existing NWB file
%% Building options Structure
%
% Writing to an existing NWB file is very similar to the above. Simply
% supply the existing NwbFile object in the 'nwb_file' field.
options = struct();
% NWB file to which to write the EXTRACT output.
options.nwb_file = nwb;
% Additionally, you can simply supply the identifier string of the TwoPhotonSeries
% object containing the data fed into the EXTRACT pipeline. The timing
% details of the ROI time series will be extracted with this information
% along with the relevant ImagingPlane object.
options.source_acquisition = 'TwoPhotonSeries';
% label for of ImageSegmentation object.  Defaults to 'ImageSegmentation'
% options.img_segmentation_name = 'ImageSegmentation'; 
% label for of PlaneSegmentation object. Defaults to 'PlaneSegmentation'
% options.plane_segmentation_name = 'PlaneSegmentation';
% unit of ROI timeseries data. Defaults to 'n.a.'
% options.data_unit = 'n.a.';
%% EXTRACT Output to NwbFile Object
% Append output data to NWB file
output_nwb = EXTRACT_output_to_nwb(output, options);
% Export NWB file
% When appending to an NWB file that was read in from disk, you MUST use the same 
% file path. Otherwise, the nwbExport function will produce an error. 
inputFilePath = '/Users/cesar/Documents/DANDI_files/sub-F1_ses-20190407T210000_behavior+ophys.nwb';
nwbExport(output_nwb, inputFilePath);

