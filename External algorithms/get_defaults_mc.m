function config = get_defaults_mc(config)

    if ~isfield(config, 'nt_template'), config.nt_template = 100; end
    if ~isfield(config, 'template'), config.template = []; end
    if ~isfield(config, 'numFrame'), config.numFrame = 1000; end
    if ~isfield(config, 'nonrigid_mc'), config.nonrigid_mc = 0; end
    if ~isfield(config, 'ns_nonrigid'), config.ns_nonrigid = 128; end
    if ~isfield(config, 'bandpass'), config.bandpass = 1; end
    if ~isfield(config, 'avg_cell_radius'), config.avg_cell_radius = 7; end
    if ~isfield(config, 'use_gpu'), config.use_gpu = 0; end
    if ~isfield(config, 'file_type'), config.file_type = 'h5'; end
    if ~isfield(config, 'mask'), config.mask = []; end
    if ~isfield(config, 'mc_template'), config.mc_template = 0; end
    if ~isfield(config, 'get_mask'), config.get_mask = 0; end
end
