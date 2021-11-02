options = struct();
% NWB file to which to write the EXTRACT output. Can be a new file or the
% same file with the data provided to the EXTRACT pipeline. If none
% provided a new file will be generated.
options.nwb_file = NwbFile( ...
    'session_start_time', '2021-01-01 00:00:00', ...
    'identifier', 'ident1', ...
    'session_description', 'EXTRACT_output_tutorial' ...
    );

% name of processing  module with optical physiology data. 
% Defaults to 'ophys'
options.processing_module_name = 'ophys'; 
% label for of ImageSegmentation object.  Defaults to 'ImageSegmentation'
options.img_segmentation_name = 'ImageSegmentation'; 
% label for of PlaneSegmentation object. Defaults to 'PlaneSegmentation'
options.plane_segmentation_name = 'PlaneSegmentation';
% unit of ROI timeseries data. Defaults to 'n.a.'
options.data_unit = 'n.a.';
% name of TwoPhotonSeries object, containing raw image data 
options.source_acquisition = 'TwoPhotonSeries';
% timing details of ROI time series. REQUIRED if source_acquisition not
% defined
options.starting_time = 0; % starting time
options.starting_time_rate = 15; %sampling rate




% %n;
% %nwb.acquisition.get('TwoPhotonSeries').starting_time_rate;
% %if these, are not provided, we can try to figure out from file
% options.imaging_plane_path = '/general/optophysiology/TwoPhotonSeries';
% %imaging_plane_path = 
% %get start time and rate from source data
% 
