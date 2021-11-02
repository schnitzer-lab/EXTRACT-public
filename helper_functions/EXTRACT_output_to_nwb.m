function nwb = EXTRACT_output_to_nwb(output, options)
% EXTRACT_output_to_nwb writes the data within the EXTRACT output structure
% to an NWB file
%
%  output: EXTRACT output structure
%
%  options: structure with details necessary for nwb file creation.
%
%

%create nwb file if none passed in
if ~isfield(options,'nwb_file')
    nwb = NwbFile( ...
    'session_start_time', '2021-01-01 00:00:00', ...
    'identifier', 'ident1', ...
    'session_description', 'EXTRACT output file' ...
    );
else
    nwb = options.nwb_file;
end
%check if timing details in ooptions structure
if (~isfield(options, 'starting_time') || ~isfield(options, s'tarting_time_rate'))
    % get timing details from nwb file, if source_acqusition define
    if isfield(options, source_acquisition)
        options.starting_time = nwb.acquisition. ...
            get(source_acquisition).starting_time;
        options.starting_time_rate = nwb.acquisition. ...
            get(source_acquisition).starting_time_rate;
    else
        error(['starting_time and starting_time_rate must be provided ', ...
        'if source_acquisition not provided'])
    end
end
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
%get imaging plane path if a source acquisition is defined
if isfield(options, 'source_acquisition')
    imaging_plane_path = types.untyped.SoftLink( ...
        nwb.acquisition.get(source_acquisition).imaging_plane.path ...
        );
else
    imaging_plane_path = [];
end

% get processing module; create if it doesn't exist
if any(strcmp(keys(nwb.processing),options.processing_module_name))
    ophys_module = nwb.processing.get(options.processing_module_name);
else
    ophys_module = types.core.ProcessingModule(...
    'description', 'holds processed calcium imaging data');
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
    'colnames', {'image_mask'}, ...
    'description', 'EXTRACT ouput', ...
    'id', types.hdmf_common.ElementIdentifiers( ...
        'data', int64(0:mask_dims(3)).'), ...
    'imaging_plane', imaging_plane_path ...
    );
% define image masks
plane_segmentation.image_mask = types.hdmf_common.VectorData( ...
    'data', output.spatial_weights, ...
    'description', 'EXTRACT image masks' ...
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
    'starting_time_rate', starting_time_rate, ... 
    'starting_time', starting_time); 
% Fluoresence or df/F depending on whether config.preprocessing value
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
summary_img = types.core.GrayscaleImage( ...
    'data', output.info.summary_image ...
    );
F_img = types.core.GrayscaleImage( ...
    'data', output.info.F_per_pixel ...
    );
max_img = types.core.GrayscaleImage( ...
    'data', output.info.max_image ...
    );
% put images in container
img_container = types.core.Images();
img_container.image.set('summary_image', summary_img);
img_container.image.set('F_per_pixel', F_img);
img_container.image.set('max_img', max_img);

%segmentation images to processing module
ophys_module.nwbdatainterface.set('EXTRACTSegmentationImages', img_container);
