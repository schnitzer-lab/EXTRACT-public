function nwb = EXTRACT_output_to_nwb(output, options)
% EXTRACT_OUTPUT_TO_NWB writes the data within the EXTRACT output structure
% to an NWB file
%
%  output: EXTRACT output structure
%
%  options: structure with details necessary for nwb file creation.
%       - nwb_file: NwbFile object specifying where to the output data.

%       - processing_module_name: identifying string of processing 
%       module with optical physiology data. Defaults to 'ophys'. Will
%       create the processing module, if none exists in file

%       - imaging_plane_name: identifying string of relevant ImagingPlane
%       object. If absent, will try to infer from file, if
%       source_acquisition provided. If both absent, will create
%       ImagingPlane object with default non-informative values
%       
%       - img_segmentation_name: identifying string of ImageSegmentation 
%       object.  Defaults to 'ImageSegmentation'.

%       - plane_segmentation_name: identifying string of PlaneSegmentation 
%       object.  Defaults to 'PlaneSegmentation'.

%       - data_unit: string identifying measuring unit of ROI timeseries
%       data (e.g., 'pixel_intensity'). Defaults to 'n.a.'

%       - source_acquisition identifying string of TwoPhotonSeries object, 
%       containing raw image data. Not necessary if writing to new NWB file.

%       - starting_time: numeric value identifying the start time of ROI
%       timeseries. Defaults to 0. Will try to infer from provided
%       NWB file if source_acquisition is defined. Supply if timing is regular.

%       - sampling_rate: numeric value identifying the sampling rate of 
%       ROI timeseries. Defaults to NaN. Will try to infer from provided
%       NWB file if source_acquisition is defined. Supply if timing is regular.

%       - timestamps: numeric array identifying timestamps of ROI time
%       series. Supply if timing is irregular.
%


% Make sure nwbFile object in options
assert((isfield(options,'nwb_file') && isa(options.nwb_file,'types.core.NWBFile')), ...
    'EXTRACT_output_to_nwb:NoNWBFile', ...
    'options structure must contain a valid NWBFile' ...
);
nwb = options.nwb_file;

%get timing details
options = get_timing_details(options);

if ~isfield(options, 'processing_module_name')
    options.processing_module_name = 'ophys';
end
if ~isfield(options, 'img_segmentation_name')
    options.img_segmentation_name = 'ImageSegmentation';
end
if ~isfield(options, 'plane_segmentation_name')
    options.plane_segmentation_name = 'PlaneSegmentation';
end
if ~isfield(options, 'data_unit')
    options.data_unit = 'n.a.';
end

if isfield(options, 'imaging_plane_name')
    % fetch defined imaging plane
    imaging_plane = nwb.general_optophysiology.get(options.imaging_plane_name);
else
    if isfield(options, 'source_acquisition')
        % infer imaging plane name, if acquisition defined
        imaging_plane_path = nwb.acquisition.get(options.source_acquisition).imaging_plane.path;
        slash_locs = strfind(imaging_plane_path,'/');
        options.imaging_plane_name = imaging_plane_path(slash_locs(end)+1:end);
        imaging_plane = nwb.general_optophysiology.get(options.imaging_plane_name);
    else
        % create imaging plane with default values
        optical_channel = types.core.OpticalChannel( ...
            'description', 'optical channel', ...
            'emission_lambda', NaN ...
        );
        device_obj = types.core.Device();
        nwb.general_devices.set('microscope', device_obj);
        imaging_plane = types.core.ImagingPlane( ...
            'optical_channel', optical_channel, ...
            'description', 'imaging plane description', ...
            'device', device_obj, ...
            'excitation_lambda', NaN, ...
            'location', 'unknown', ...
            'indicator', 'unknown' ...
        );
        % attach to nwb file
        nwb.general_optophysiology.set('ImagingPlane', imaging_plane);
    end
end

% get processing module; create if it doesn't exist
if any(strcmp(keys(nwb.processing),options.processing_module_name))
    ophys_module = nwb.processing.get(options.processing_module_name);
else
    ophys_module = types.core.ProcessingModule('description', 'holds processed calcium imaging data');
    nwb.processing.set(options.processing_module_name, ophys_module);
end
% get dimension of ROI masks 
mask_dims = size(output.spatial_weights);
% introduce singleton dimension, if neccesary
if length(mask_dims) < 3
    mask_dims(3) = 1;
end
% define plane segmentation object
plane_segmentation = types.core.PlaneSegmentation( ...
    'colnames', {'image_mask','metrics','is_attr_bad','is_bad'}, ...
    'description', 'EXTRACT ouput', ...
    'id', types.hdmf_common.ElementIdentifiers( ...
        'data', int64(0:mask_dims(3)).'), ...
    'imaging_plane', imaging_plane ...
);
% define image masks
plane_segmentation.image_mask = types.hdmf_common.VectorData( ...
    'data', output.spatial_weights, ...
    'description', 'EXTRACT image masks' ...
);
% define EXTRACT cellcheck fields
plane_segmentation.vectordata.set('metrics', types.hdmf_common.VectorData( ...
        'data', output.info.cellcheck.metrics, ...
        'description', 'EXTRACT cellcheck metrics field' ...
    ) ...
);
plane_segmentation.vectordata.set('is_attr_bad', types.hdmf_common.VectorData( ...
        'data', output.info.cellcheck.is_attr_bad, ...
        'description', 'EXTRACT cellcheck is_attr_bad field' ...
    ) ...
);
plane_segmentation.vectordata.set('is_bad', types.hdmf_common.VectorData( ...
        'data', output.info.cellcheck.is_bad, ...
        'description', 'EXTRACT cellcheck is_bad field' ...
    ) ...
);
% define image segmentation object and place in module
img_seg = types.core.ImageSegmentation();
img_seg.planesegmentation.set(options.plane_segmentation_name, plane_segmentation);
ophys_module.nwbdatainterface.set(options.img_segmentation_name, img_seg);
% Dynamic table region with reference to ROIs
roi_table_region = types.hdmf_common.DynamicTableRegion( ...
    'table', types.untyped.ObjectView(plane_segmentation), ...
    'description', 'all_rois', ...
    'data', [0 mask_dims(3)-1]' ...
);
roi_response_series = types.core.RoiResponseSeries( ...
    'rois', roi_table_region, ...
    'data', output.temporal_weights, ...
    'data_unit', options.data_unit, ... 
    'starting_time_rate', options.sampling_rate, ... 
    'starting_time', options.starting_time, ...
    'timestamps', options.timestamps ...
); 
% Fluoresence or df/F depending on config.preprocess value
if output.config.preprocess
    output_timeseries = types.core.DfOverF();
    output_timeseries.roiresponseseries.set('RoiResponseSeries', roi_response_series);
    ophys_module.nwbdatainterface.set('DfoverF', output_timeseries);
else
    output_timeseries = types.core.Fluorescence();
    output_timeseries.roiresponseseries.set('RoiResponseSeries', roi_response_series);
    ophys_module.nwbdatainterface.set('Fluorescence', output_timeseries);
end

% output images to GrayScale types
summary_img = types.core.GrayscaleImage('data', output.info.summary_image);
F_img = types.core.GrayscaleImage('data', output.info.F_per_pixel);
max_img = types.core.GrayscaleImage('data', output.info.max_image);
% put images in container
img_container = types.core.Images('description', 'EXTRACT info images');
img_container.image.set('summary_image', summary_img);
img_container.image.set('F_per_pixel', F_img);
img_container.image.set('max_img', max_img);
% segmentation images to processing module
ophys_module.nwbdatainterface.set('EXTRACTSegmentationImages', img_container);
end
function options = get_timing_details(options)
% resolve timing details, infer when necessary and possible
% if no information is provided, defaults to regular timing values
if isfield(options, 'source_acquisition')
    if ~isfield(options, 'timestamps')
        if ~isfield(options, 'starting_time') || ~isfield(options, 'sampling_rate')
            options.timestamps = options.nwb_file.acquisition.get(options.source_acquisition).timestamps;
            if isempty(options.timestamps)
                options.starting_time = options.nwb_file.acquisition. ... 
                    get(options.source_acquisition).starting_time;
                options.sampling_rate = options.nwb_file.acquisition. ...
                    get(options.source_acquisition).starting_time_rate;
            end
        else
            options.timestamps = [];
        end
    else
        options.starting_time = [];
        options.sampling_rate = [];
    end
else
    if ~isfield(options, 'timestamps')
        if ~isfield(options, 'starting_time') || ~isfield(options, 'sampling_rate')
            options.starting_time = 0;
            options.sampling_rate = NaN;
            options.timestamps = [];
        else
            options.timestamps = [];
        end
    else
        options.starting_time = [];
        options.sampling_rate = [];
    end
end
end
