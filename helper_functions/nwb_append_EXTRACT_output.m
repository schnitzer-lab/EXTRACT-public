%function nwb_append_EXTRACT_output(nwb, output)

% create NwbFile object with required fields
nwb = NwbFile( ...
    'session_start_time', '2021-01-01 00:00:00', ...
    'identifier', 'ident1', ...
    'session_description', 'EXTRACT_output_tutorial' ...
    );

% hard-code these variables, for now
processing_module_name = 'ophys';
img_segmentation_name = 'ImageSegmentation'; 
plane_segmentation_name = 'PlaneSegmentation'; 
data_unit = 'n.a.';

%if these, are not provided, we can try to figure out from file
imaging_plane_path = '/general/optophysiology/TwoPhotonSeries';
%imaging_plane_path = nwb.acquisition.get('TwoPhotonSeries'). ...
 %   imaging_plane.path;
%get start time and rate from source data
starting_time_rate = 0;%nwb.acquisition.get('TwoPhotonSeries').starting_time_rate;
starting_time = 15;%nwb.acquisition.get('TwoPhotonSeries').starting_time;



% get processing module; create if it doesn't exist
if any(strcmp(keys(nwb.processing),processing_module_name))
    ophys_module = nwb.processing.get(processing_module_name);
else
    ophys_module = types.core.ProcessingModule(...
    'description', 'holds processed calcium imaging data');
    nwb.processing.set(processing_module_name, ophys_module);
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
    'imaging_plane', types.untyped.SoftLink(imaging_plane_path) ...
    );
% define image masks
plane_segmentation.image_mask = types.hdmf_common.VectorData( ...
    'data', output.spatial_weights, ...
    'description', 'EXTRACT image masks' ...
    );
% define image segmentation object and place in module
img_seg = types.core.ImageSegmentation();
img_seg.planesegmentation.set(plane_segmentation_name, plane_segmentation);
ophys_module.nwbdatainterface.set(img_segmentation_name, img_seg);
% Dynamic table region with reference to ROIs
roi_table_region = types.hdmf_common.DynamicTableRegion( ...
    'table', types.untyped.ObjectView(plane_segmentation), ...
    'description', 'all_rois', ...
    'data', [0 mask_dims(3)-1]' ...
    );
roi_response_series = types.core.RoiResponseSeries( ...
    'rois', roi_table_region, ...
    'data', output.temporal_weights, ...
    'data_unit', data_unit, ... %needs to be defined by user
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
