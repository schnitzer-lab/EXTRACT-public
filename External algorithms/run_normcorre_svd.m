function run_normcorre_svd(input,output,config)

nt_template     = config.nt_template;
temporal_ds     = config.temporal_ds;
template        = config.template;
numFrame        = config.numFrame;
nonrigid_mc     = config.nonrigid_mc;
ns_nonrigid     = config.ns_nonrigid;
bandpass        = config.bandpass;
avg_cell_radius = config.avg_cell_radius;
use_gpu         = config.use_gpu;
file_type       = config.file_type;
svd_flag        = config.svd_flag;


switch file_type
    case 'h5'
        [input_filename,input_datasetname] = parse_movie_name(input);
end

[output_filename,output_datasetname] = parse_movie_name(output);



if isfile(output_filename)
    delete(output_filename);
end


movie_info = h5info(input_filename,input_datasetname);
movie_size = num2cell(movie_info.Dataspace.Size);
[nx, ny, totalnum] = deal(movie_size{:});

try
h5create(output_filename,output_datasetname,[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,numFrame]);
catch 
h5create(output_filename,output_datasetname,[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,round(numFrame/2)]);
end

windowsize = min(totalnum, numFrame);

startno = [1:windowsize:totalnum];


% handling the irregular framenumbers 
perframes = ones(numel(startno),1)*numFrame;

lastframes = mod(totalnum,numFrame);

if lastframes > 0
    perframes(end-1) = perframes(end-1) + lastframes;
    startno(end) = [];
end



if isempty(template)
    switch file_type
        case 'h5'
            im1 = single(h5read(input_filename, input_datasetname, [1, 1, 1], [nx, ny, nt_template]));   %Create downsampled reference image for motion correction
        case 'tif'
            im1 = single(read_from_tif(input,1,nt_template));
        case 'tiff'
            im1 = single(read_from_tif(input,1,nt_template));
    end

    if bandpass
        im1 = spatial_bandpass(im1,avg_cell_radius,10,2,use_gpu);
    end

    if svd_flag
        im1 = denoisingSVD(im1);
    end

    %im_ds= single(max(im1,[],3));
    im_ds= single(mean(im1,3));
    clear im1
else
    im_ds = single(template);
end

disp(sprintf('%s: Running motion correction split into %s movies', datestr(now),num2str(numel(startno)) ))




for i=1:numel(startno)
    % parfor can even improve, but h5write is too slow thus missing data
    disp(sprintf('\t %s: Processing %s/%s movies', datestr(now),num2str(i),num2str(numel(startno)) ))

    switch file_type
        case 'h5'
            M_block = single(h5read(input_filename,input_datasetname,[1,1,startno(i)],[nx,ny,perframes(i)]));
        case 'tif'
            M_block = single(read_from_tif(input,startno(i),perframes(i)));
        case 'tiff'
            M_block = single(read_from_tif(input,startno(i),perframes(i)));
    end
    
    
    
    if temporal_ds > 1
        M_block_ds = downsample_time(M_block,temporal_ds); %Run motion correction on downsampled movie
    else
        M_block_ds = M_block;
    end

    if bandpass
        M_block_ds = spatial_bandpass(M_block_ds,avg_cell_radius,10,2,use_gpu);
    end
    
    if svd_flag
        M_block_ds = denoisingSVD(M_block_ds);   %Run motion correction on denoised movie
    end
    
    
    
    disp(sprintf('\t \t %s: Starting rigid motion correction ', datestr(now)))
    options_rigid = NoRMCorreSetParms('d1',nx,'d2',ny, ... 
                                         'max_shift',30,'us_fac',30,'grid_size',[nx,ny],'print_msg',0);
    [~,shifts2,template2,options_rigid] = normcorre_batch(M_block_ds,options_rigid,im_ds);

    
    clear M_block_ds
    

    for n = 1:size(M_block,3)   %Upsample motion correction shifts and apply to full resolution block
        if n/temporal_ds > length(shifts2)
            shifts_us(n).shifts = shifts2(ceil(n/temporal_ds)-1).shifts;
            shifts_us(n).shifts_up = shifts2(ceil(n/temporal_ds)-1).shifts_up;
            shifts_us(n).diff = shifts2(ceil(n/temporal_ds)-1).diff;
        else
            shifts_us(n).shifts = shifts2(ceil(n/temporal_ds)).shifts;
            shifts_us(n).shifts_up = shifts2(ceil(n/temporal_ds)).shifts_up;
            shifts_us(n).diff = shifts2(ceil(n/temporal_ds)).diff;
        end
    end
    M_block_rigid = zeros([nx, ny, perframes(i)],'single');
    M_block_rigid = apply_shifts(M_block,shifts_us,options_rigid);

    clear M_block
    clear shifts_us


    if nonrigid_mc


        disp(sprintf('\t \t %s: Starting non-rigid motion correction ', datestr(now)))

        if temporal_ds > 1
            M_block_ds = downsample_time(M_block_rigid,temporal_ds); %Run motion correction on downsampled movie
        else
            M_block_ds = M_block_rigid;
        end


        if bandpass
            M_block_ds = spatial_bandpass(M_block_ds,avg_cell_radius,10,2,use_gpu);
        end
        
        if svd_flag
            M_block_ds = denoisingSVD(M_block_ds);   %Run motion correction on denoised movie
        end

        
        
        
        options_nonrigid = NoRMCorreSetParms('d1',nx,'d2',ny, ... 
                                             'max_shift',30,'us_fac',30,'grid_size',[ns_nonrigid,ns_nonrigid],'print_msg',0);
        [~,shifts2,template2,options_nonrigid] = normcorre_batch(M_block_ds,options_nonrigid,im_ds); 

        
        clear M_block_ds
        

        for n = 1:size(M_block_rigid,3)   %Upsample motion correction shifts and apply to full resolution block
            if n/temporal_ds > length(shifts2)
                shifts_us(n).shifts = shifts2(ceil(n/temporal_ds)-1).shifts;
                shifts_us(n).shifts_up = shifts2(ceil(n/temporal_ds)-1).shifts_up;
                shifts_us(n).diff = shifts2(ceil(n/temporal_ds)-1).diff;
            else
                shifts_us(n).shifts = shifts2(ceil(n/temporal_ds)).shifts;
                shifts_us(n).shifts_up = shifts2(ceil(n/temporal_ds)).shifts_up;
                shifts_us(n).diff = shifts2(ceil(n/temporal_ds)).diff;
            end
        end

        M_block_MC_us = zeros([nx, ny, perframes(i)],'single');
        M_block_MC_us = apply_shifts(M_block_rigid,shifts_us,options_nonrigid);
        clear shifts_us
    else
        disp(sprintf('\t \t %s: No non-rigid motion correction', datestr(now)))

        M_block_MC_us = M_block_rigid;
        
    end


    disp(sprintf('\t \t %s: Saving the motion corrected movie ', datestr(now)))

    h5write(output_filename,output_datasetname,single(M_block_MC_us),[1,1,startno(i)],[nx,ny,size(M_block_MC_us,3)]);

    clear M_block_MC_us
    
end
disp(sprintf('%s: Motion correction finished', datestr(now)))

end
   