function downsamplespace_pipeline(input,blocks,dt,totalnum)

[filename,datasetname] = parse_movie_name(input);

filename  = filename(1:end-3);

hinfo=h5info([filename '.h5']);
if nargin <4
    totalnum = hinfo.Datasets.Dataspace.Size(3);
end
nx = hinfo.Datasets.Dataspace.Size(1);
ny = hinfo.Datasets.Dataspace.Size(2);

numFrame = totalnum/blocks;

outputfilename = [filename '_space_ds'];

if isfile([outputfilename '.h5'])
    delete([outputfilename '.h5']);
end

try
h5create([outputfilename '.h5'],datasetname,[nx/dt ny/dt totalnum],'Datatype','single','ChunkSize',[nx/dt,ny/dt,numFrame]);
catch
h5create([outputfilename '.h5'],datasetname,[nx/dt ny/dt totalnum],'Datatype','single','ChunkSize',[nx/dt,ny/dt,numFrame/(10)]);
end

disp(sprintf('%s: Downsampling in space by a factor of %s, split into %s movies', datestr(now),num2str(dt),num2str(blocks) ))


for i=1:numFrame:totalnum
    
    fprintf('\t %s: Running %i out of %i parts \n',datestr(now),round(i/numFrame)+1,totalnum/numFrame);
    data = h5read([filename '.h5'],datasetname,[1,1,i],[nx,ny,numFrame]);
    
    [movie_out] = downsample_space(data,dt);
    
   
    
    h5write([outputfilename '.h5'],datasetname,single(movie_out),[1,1,i],[nx/dt,ny/dt,round(numFrame)]);
   
    
end
disp(sprintf('%s: Space downsampling finished ', datestr(now)))
end


