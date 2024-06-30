function preprocess_save(input,config)
if nargin < 2
    config = [];
end

config = get_defaults(config);
try
    gpuDevice(1);
catch
    config.use_gpu = 0;
    disp(datestr(now) + ": No GPU detected, using CPU instead")
end

if ~isfield(config, 'partition_size_time')
    partition_size_time = 10000; 
else
    partition_size_time = config.partition_size_time;
end
time_dt = config.downsample_time_by; 


[filename,datasetname] = parse_movie_name(input);
filename  = filename(1:end-3);
filename_df = [filename '_df'];
filename_final = [filename '_final'];


hinfo=h5info([filename '.h5']);
nt = hinfo.Datasets.Dataspace.Size(3);
nx = hinfo.Datasets.Dataspace.Size(1);
ny = hinfo.Datasets.Dataspace.Size(2);

if isfile([filename_df '.h5'])
    delete([filename_df '.h5']);
    disp(datestr(now) + ": Deleted the file" + [filename_df '.h5'])
end
if isfile([filename_final '.h5'])
    delete([filename_final '.h5']);
    disp(datestr(now) + ": Deleted the file" + [filename_final '.h5'])
end

error_flag = 1;
t_chunk = 1000;
while error_flag == 1
    try
        h5create([filename_final '.h5'],datasetname,[nx ny nt],'Datatype','single','ChunkSize',[nx,ny,t_chunk]);
        h5create([filename_df '.h5'],datasetname,[nx ny nt],'Datatype','single','ChunkSize',[nx,ny,t_chunk]);
        error_flag = 0;
    catch
        t_chunk = round(t_chunk/2);
    end
end
h5create([filename_final '.h5'],'/F_per_pixel',[nx ny],'Datatype','single');
h5create([filename_df '.h5'],'/F_per_pixel',[nx ny],'Datatype','single');


% Run the df process
fprintf('%s: Calculating F_per_pixel ... \n',datestr(now));
m = zeros(nx,ny);
[perframes,startno] = get_partition_starters(nt,2*partition_size_time);
for i=1:numel(startno)
    fprintf('\t \t \t %s: Running %i out of %i parts \n',datestr(now),i,numel(startno));
    M = single(h5read([filename '.h5'],datasetname,[1,1,startno(i)],[nx,ny,perframes(i)]));
    m = m+sum(M,3);
end

m = m/nt;

h5write([filename_df '.h5'],'/F_per_pixel',m);
h5write([filename_final '.h5'],'/F_per_pixel',m);

% Compute the highpass movie
fprintf('%s: Running Highpass filtering ... \n',datestr(now));
[perframes,startno] = get_partition_starters(nt,partition_size_time);
for i=1:numel(startno)
    fprintf('\t \t \t %s: Running %i out of %i parts \n',datestr(now),i,numel(startno));
    M = single(h5read([filename '.h5'],datasetname,[1,1,startno(i)],[nx,ny,perframes(i)]));

    M = M -m;
    h5write([filename_df '.h5'],datasetname,M,[1,1,startno(i)],[nx,ny,perframes(i)]);
    M = spatial_bandpass(M, config.avg_cell_radius, ...
                config.spatial_highpass_cutoff, inf, config.use_gpu);

    h5write([filename_final '.h5'],datasetname,M,[1,1,startno(i)],[nx,ny,perframes(i)]); 
    clear M
end

if time_dt>1
try
    downsampletime_pipeline([filename_final '.h5:' datasetname],time_dt)
    h5create([filename_final '_downsampled.h5'],'/F_per_pixel',[nx ny],'Datatype','single');
    F_per_pixel = h5read([filename_df '.h5'],'/F_per_pixel');
    h5write([filename_final '_downsampled.h5'],'/F_per_pixel',F_per_pixel);
catch
    fprintf('%s: Time downsampling failed. \n',datestr(now))
end
end
fprintf('%s: Preprocessing finished. \n',datestr(now));


end



function [perframes,startno] = get_partition_starters(totalnum,numFrame)

    windowsize = min(totalnum, numFrame);
    
    startno = [1:windowsize:totalnum];
    
    if numel(startno)>1
        % handling the irregular framenumbers 
        perframes = ones(numel(startno),1)*numFrame;
    
        lastframes = mod(totalnum,numFrame);
    
        if lastframes > 0
            perframes(end-1) = perframes(end-1) + lastframes;
            startno(end) = [];
        end
    
    else
        perframes = totalnum;
    end
end
