function nwb = EXTRACT_output_to_nwb(output, options)
% EXTRACT_OUTPUT_TO_NWB writes the data within the EXTRACT output structure
% to an NWB file
%
%  output: EXTRACT output structure
%
%  options: structure with details necessary for nwb file creation.
%       - nwb_file: either an nwb file or a substructure with parameters to 
%       create the NWB file. If any of the required parameters is missing, 
%       default values will be used when creating the file. Parameters include:
%       session_start_time, identifier, and session_dewcription.
%
%       - processing_module_name: identifying string of processing 
%       module with optical physiology data. Defaults to 'ophys'. Will
%       create the processing module, if none exists in file

%       - imaging_plane: substructure with parameters to fetch or create the
%       relevant ImagingPlane object. If any of the required parameters is
%       missing, default values will be used when creating the object. 
%       Parameters include: name, description, excitation_lambda,
%       imaging_rate, indicator, and location
%
%       - device_name: identifying string of Device object used when creating new
%       ImagingPlane object

%       - optical channel: substructure with parameters to create
%       OpticalChannel used when creating new Imaging plane object.
%       Parameters include: description, emission_lambda
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

% If NWB file not provided, create NWB file with provided details
if ~isa(options.nwb_file,'types.core.NWBFile')
    options = make_nwb_file(options);
end

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

if isfield(options, 'imaging_plane')
    if isfield(options.imaging_plane, 'name')
        % try fetching defined imaging plane
        try
            imaging_plane = option.nwb_file.general_optophysiology.get(options.imaging_plane.name);
        catch
            imaging_plane = get_or_make_imaging_plane(options);
        end
    end
else
    imaging_plane = get_or_make_imaging_plane(options);
end

%retrieve nwb file
nwb = options.nwb_file;

% get processing module; create if it doesn't exist
if any(strcmp(keys(nwb.processing),options.processing_module_name))
    ophys_module = nwb.processing.get(options.processing_module_name);
else
    ophys_module = types.core.ProcessingModule( ...
        'description', 'holds processed calcium imaging data' ...
    );
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

% parameters that may have numeric or string values
num_or_char_params = { ...
    'downsample_time_by', ...
    'downsample_space_by' ...
};

% ignore operational config parameters
ignore_params = { ...
    'use_gpu', ...
    'parallel_cpu', ...
    'multi_gpu', ...
    'use_default_gpu', ...
    'plot_loss', ...
    'verbose', ...
    'num_frames', ...
    'is_pixel_valid' ...
};
% define EXCTACTsegmentation object
img_seg = types.ndx_extract.EXTRACTSegmentation();
config_params = fieldnames(output.config);
for i = 1:length(config_params)
    if ~any(strcmpi(config_params{i}, ignore_params))
        if strcmp(config_params{i},'thresholds')
            % unroll threshold params
            thresh_params = fieldnames(output.config.thresholds);
            for t = 1:length(thresh_params)
                img_seg.(thresh_params{t}) = output.config.thresholds.(thresh_params{t});
            end
        elseif any(strcmpi(config_params{i}, num_or_char_params))
            % if downsample parameters are strings (i.e. 'auto'), leave blank
            if ~isa(output.config.(config_params{i}),'char')
                img_seg.(config_params{i}) = output.config.(config_params{i});
            end
        else
            img_seg.(config_params{i}) = output.config.(config_params{i});
        end
    end
end
% attach plane segmentation and attach to module
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
function options = make_nwb_file(options)
    if ~isfield(options,'nwb_file')
        options.nwb_file.session_start_time =  '2021-01-01 00:00:00';
        options.nwb_file.identifier = char(java.util.UUID.randomUUID.toString);
        options.nwb_file.session_description = 'EXTRACT output file';
    else
        if ~isfield (options.nwb_file,'session_start_time')
            options.nwb_file.session_start_time =  '2021-01-01 00:00:00';
        end
        if ~isfield (options.nwb_file,'identifier')
            options.nwb_file.identifier = char(java.util.UUID.randomUUID.toString);
        end
        if ~isfield (options.nwb_file,'session_description')
            options.nwb_file.session_description = 'EXTRACT output file';
        end
    end
    % generate file
    nwb = NwbFile();
    nwb_file_props = fieldnames(options.nwb_file);
    for i = 1:length(nwb_file_props)
        nwb.(nwb_file_props{i}) = options.nwb_file.(nwb_file_props{i});
    end
    options.nwb_file = nwb;
end
function imaging_plane = get_or_make_imaging_plane(options)
    if isfield(options, 'source_acquisition')
        % infer imaging plane name, if acquisition defined
        imaging_plane_path = options.nwb_file.acquisition.get(options.source_acquisition).imaging_plane.path;
        slash_locs = strfind(imaging_plane_path,'/');
        options.imaging_plane_name = imaging_plane_path(slash_locs(end)+1:end);
        imaging_plane = options.nwb_file.general_optophysiology.get(options.imaging_plane_name);
    else
        if ~isfield(options,'device_name')
            options.device_name = 'microscope';
        end
        if isfield(options,'optical_channel')
            if ~isfield(options.optical_channel,'description')
                options.optical_channel.description = 'optical channel';
            end
            if ~isfield(options.optical_channel,'emission_lambda')
                options.optical_channel.emission_lambda = NaN;
            end
        else
            options.optical_channel.description = 'optical channel';
            options.optical_channel.emission_lambda = NaN;
        end
        if isfield(options,'imaging_plane')
            if ~isfield(options.imaging_plane, 'name')
                options.imaging_plane.name = 'ImagingPlane';
            end
            if ~isfield(options.imaging_plane, 'description')
                options.imaging_plane.description = 'imaging plane description';
            end
            if ~isfield(options.imaging_plane, 'excitation_lambda')
                options.imaging_plane.excitation_lambda = NaN;
            end
            if ~isfield(options.imaging_plane, 'imaging_rate')
                options.imaging_plane.imaging_rate = NaN;
            end
            if ~isfield(options.imaging_plane, 'indicator')
                options.imaging_plane.indicator = 'unknown';
            end
            if ~isfield(options.imaging_plane, 'location')
                options.imaging_plane.location = 'unknown';
            end

        else
            options.imaging_plane.name = 'ImagingPlane';
            options.imaging_plane.description = 'imaging plane description';
            options.imaging_plane.excitation_lambda = NaN;
            options.imaging_plane.imaging_rate = NaN;
            options.imaging_plane.indicator = 'unknown';
            options.imaging_plane.location = 'unknown';
        end
        
        % create imaging plane with default values
        optical_channel = types.core.OpticalChannel( ...
            'description', options.optical_channel.description, ...
            'emission_lambda', options.optical_channel.emission_lambda ...
        );
        device_obj = types.core.Device();
        options.nwb_file.general_devices.set(options.device_name , device_obj);
        imaging_plane = types.core.ImagingPlane( ...
            'optical_channel', optical_channel, ...
            'device', device_obj ...
        );
        imaging_plane_props = fieldnames(options.imaging_plane);
        for i = 1:length(imaging_plane_props)
            if ~strcmp(imaging_plane_props{i},'name')
                imaging_plane.(imaging_plane_props{i}) = options.imaging_plane.(imaging_plane_props{i});
            end
        end
        % attach to nwb file
        options.nwb_file.general_optophysiology.set(options.imaging_plane.name, imaging_plane);
    end
end
