function cropmovie_pipeline(input,file_type,numFrame,totalnum)

if nargin <2
    file_type = 'h5';
end

if nargin <3
    numFrame = 3000;
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


outputfilename = [filename '_cropped'];

if isfile([outputfilename '.h5'])
    delete([outputfilename '.h5']);
end


switch file_type
    case 'h5'
        data = single(h5read([filename '.h5'],datasetname,[1,1,1],[nx,ny,10]));
    case 'tif'
        data = single(read_from_tif(input,1,10));
    case 'tiff'
        data = single(read_from_tif(input,1,10));
end

imshow(mean(data,3),[])
rect = getrect;
y_min = max(round(rect(1)),0);
x_min = max(round(rect(2)),0);
y_max = min(round(rect(1)+rect(3)),ny);
x_max = min(round(rect(2)+rect(4)),nx);

nx_new = x_max - x_min + 1;
ny_new = y_max - y_min + 1;

try
    h5create([outputfilename '.h5'],datasetname,[nx_new ny_new totalnum],'Datatype','single','ChunkSize',[nx_new,ny_new,numFrame]);
catch
    h5create([outputfilename '.h5'],datasetname,[nx_new ny_new totalnum],'Datatype','single','ChunkSize',[nx_new,ny_new,round(numFrame/10)]);
end


disp(sprintf('%s: Cropping the movie, split into %s parts', datestr(now),num2str(numel(startno)) ))


for i=1:numel(startno)
    
    fprintf('\t %s: Running %i out of %i parts \n',datestr(now),i,numel(startno));
    switch file_type
        case 'h5'
            data = single(h5read([filename '.h5'],datasetname,[1,1,startno(i)],[nx,ny,perframes(i)]));
        case 'tif'
            data = single(read_from_tif(input,startno(i),perframes(i)));
        case 'tiff'
            data = single(read_from_tif(input,startno(i),perframes(i)));
    end
    
    movie_out = data(x_min:x_max,y_min:y_max,:);
    
    
    h5write([outputfilename '.h5'],datasetname,single(movie_out),[1,1,startno(i)],[nx_new,ny_new,perframes(i)]);
   
    
end
disp(sprintf('%s: Cropping finished ', datestr(now)))
end


