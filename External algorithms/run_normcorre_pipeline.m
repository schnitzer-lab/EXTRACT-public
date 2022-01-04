function run_normcorre_pipeline(input,output,config)

nt_template     = config.nt_template;
template        = config.template;
numFrame        = config.numFrame;
nonrigid_mc     = config.nonrigid_mc;
ns_nonrigid     = config.ns_nonrigid;
bandpass        = config.bandpass;
avg_cell_radius = config.avg_cell_radius;
use_gpu         = config.use_gpu;
file_type       = config.file_type;


switch file_type
    case 'h5'
        [input_filename,input_datasetname] = parse_movie_name(input);
        movie_info = h5info(input_filename,input_datasetname);
        movie_size = num2cell(movie_info.Dataspace.Size);
        [nx, ny, totalnum] = deal(movie_size{:});
    case 'tif'
        tiff_info = imfinfo(input);
        nx = tiff_info(1).Height;
        ny = tiff_info(1).Width;
        totalnum = size(tiff_info, 1);
    case 'tiff'
        tiff_info = imfinfo(input);
        nx = tiff_info(1).Height;
        ny = tiff_info(1).Width;
        totalnum = size(tiff_info, 1);
end



[output_filename,output_datasetname] = parse_movie_name(output);



if isfile(output_filename)
    delete(output_filename);
end


try
    h5create(output_filename,output_datasetname,[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,numFrame]);
catch 
    h5create(output_filename,output_datasetname,[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,ceil(numFrame/10)]);
end

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

if nt_template > totalnum
    nt_template = totalnum;
end


if isempty(template)
    disp(sprintf('%s: Getting the template for motion correction from the first %s frames', datestr(now), num2str(nt_template) ))
    switch file_type
        case 'h5'
            im1 = single(h5read(input_filename, input_datasetname, [1, 1, 1], [nx, ny, nt_template]));   
        case 'tif'
            im1 = single(read_from_tif(input,1,nt_template));
        case 'tiff'
            im1 = single(read_from_tif(input,1,nt_template));
    end

    if bandpass
        im1 = spatial_bandpass(im1,avg_cell_radius,10,2,use_gpu);
    end


    %im_ds= single(max(im1,[],3));
    im_ds= single(mean(im1,3));
    clear im1
else
    im_ds = single(template);
end

disp(sprintf('%s: Running motion correction split into %s movies', datestr(now),num2str(numel(startno)) ))




for i=1:numel(startno)
    
    disp(sprintf('\t %s: Processing %s/%s movies', datestr(now),num2str(i),num2str(numel(startno)) ))

    switch file_type
        case 'h5'
            M = single(h5read(input_filename,input_datasetname,[1,1,startno(i)],[nx,ny,perframes(i)]));
        case 'tif'
            M = single(read_from_tif(input,startno(i),perframes(i)));
        case 'tiff'
            M = single(read_from_tif(input,startno(i),perframes(i)));
    end
    
    
    

    if bandpass
        M_proc = spatial_bandpass(M,avg_cell_radius,10,2,use_gpu);
    else
        M_proc = M;
    end
    

    
    
    
    disp(sprintf('\t \t %s: Starting rigid motion correction ', datestr(now)))

    options_rigid = NoRMCorreSetParms('d1',nx,'d2',ny,'max_shift',30,'us_fac',30,'grid_size',[nx,ny],'print_msg',0); 
    % The grid size is full FOV
    [~,shifts_rigid,~,options_rigid] = normcorre_batch(M_proc,options_rigid,im_ds);

    
    clear M_proc
    


    M_rigid = zeros([nx, ny, perframes(i)],'single');
    M_rigid = apply_shifts(M,shifts_rigid,options_rigid);

    clear M
    clear shifts_rigid


    if nonrigid_mc


        disp(sprintf('\t \t %s: Starting non-rigid motion correction ', datestr(now)))



        if bandpass
            M_proc = spatial_bandpass(M_rigid,avg_cell_radius,10,2,use_gpu);
        else
            M_proc = M_rigid;
        end

        
        
        
        options_nonrigid = NoRMCorreSetParms('d1',nx,'d2',ny,'max_shift',30,'us_fac',30,'grid_size',[ns_nonrigid,ns_nonrigid],'print_msg',0);
        [~,shifts_nonrigid,~,options_nonrigid] = normcorre_batch(M_proc,options_nonrigid,im_ds); 

        
        clear M_proc
        

        M_final = zeros([nx, ny, perframes(i)],'single');
        M_final = apply_shifts(M_rigid,shifts_nonrigid,options_nonrigid);

        clear shifts_nonrigid
        clear M_rigid
    else
        disp(sprintf('\t \t %s: No non-rigid motion correction', datestr(now)))

        M_final= M_rigid;
        clear M_rigid
        
    end


    disp(sprintf('\t \t %s: Saving the motion corrected movie ', datestr(now)))

    h5write(output_filename,output_datasetname,single(M_final),[1,1,startno(i)],[nx,ny,perframes(i)]);

    clear M_final
    
end
disp(sprintf('%s: Motion correction finished', datestr(now)))

end
   
