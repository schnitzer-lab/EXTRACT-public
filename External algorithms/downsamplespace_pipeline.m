function downsamplespace_pipeline(input,blocks,dt,file_type,totalnum)

if nargin <4
    file_type = 'h5';
end

switch file_type
    case 'h5'
        [filename,datasetname] = parse_movie_name(input);
        filename  = filename(1:end-3);

        hinfo=h5info([filename '.h5']);
        if nargin <5
            totalnum = hinfo.Datasets.Dataspace.Size(3);
        end
        nx = hinfo.Datasets.Dataspace.Size(1);
        ny = hinfo.Datasets.Dataspace.Size(2);
    case 'tif'
        tiff_info = imfinfo(input);
        nx = tiff_info(1).Height;
        ny = tiff_info(1).Width;
        if nargin < 5
            totalnum = size(tiff_info, 1);
        end

        filename = input(1:end-4);
        datasetname = '/Data';

    case 'tiff'
        tiff_info = imfinfo(input);
        nx = tiff_info(1).Height;
        ny = tiff_info(1).Width;
        if nargin < 5
            totalnum = size(tiff_info, 1);
        end

        filename = input(1:end-5);
        datasetname = '/Data';
end



numFrame = totalnum/blocks;

outputfilename = [filename '_space_ds'];

if isfile([outputfilename '.h5'])
    delete([outputfilename '.h5']);
end

try
h5create([outputfilename '.h5'],datasetname,[nx/dt ny/dt totalnum],'Datatype','single','ChunkSize',[nx/dt,ny/dt,numFrame]);
catch
h5create([outputfilename '.h5'],datasetname,[nx/dt ny/dt totalnum],'Datatype','single','ChunkSize',[nx/dt,ny/dt,round(numFrame/10)]);
end

disp(sprintf('%s: Downsampling in space by a factor of %s, split into %s movies', datestr(now),num2str(dt),num2str(blocks) ))


for i=1:numFrame:totalnum
    
    fprintf('\t %s: Running %i out of %i parts \n',datestr(now),round(i/numFrame)+1,totalnum/numFrame);
    switch file_type
        case 'h5'
            data = single(h5read([filename '.h5'],datasetname,[1,1,i],[nx,ny,numFrame]));
        case 'tif'
            data = single(read_from_tif(input,i,numFrame));
        case 'tiff'
            data = single(read_from_tif(input,i,numFrame));
    end
    
    [movie_out] = downsample_space(data,dt);
    
    h5write([outputfilename '.h5'],datasetname,single(movie_out),[1,1,i],[nx/dt,ny/dt,round(numFrame)]);
   
    
end
disp(sprintf('%s: Space downsampling finished ', datestr(now)))
end


