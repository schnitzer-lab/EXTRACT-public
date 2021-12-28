function downsampletime_pipeline(input,blocks,dt)

[filename,datasetname] = parse_movie_name(input);

filename  = filename(1:end-3);

hinfo=h5info([filename '.h5']);
totalnum = hinfo.Datasets.Dataspace.Size(3);
nx = hinfo.Datasets.Dataspace.Size(1);
ny = hinfo.Datasets.Dataspace.Size(2);

if (mod(totalnum,blocks) ~= 0 || mod(totalnum,blocks*dt) ~= 0)
    error('Pick dt and num_blocks more carefully!')
end

numFrame = totalnum/blocks;

outputfilename = [filename '_downsampled'];

h5create([outputfilename '.h5'],datasetname,[nx ny totalnum/dt],'Datatype','single','ChunkSize',[nx,ny,numFrame/dt]);
k=1;
for i=1:numFrame:totalnum
    tic
    fprintf('Running %i out of %i parts \n',round(i/numFrame)+1,totalnum/numFrame);
    data = h5read([filename '.h5'],datasetname,[1,1,i],[nx,ny,numFrame]);
    
    [movie_out] = downsample_time(data,dt);
    
   
    
    h5write([outputfilename '.h5'],datasetname,single(movie_out),[1,1,k],[nx,ny,round(numFrame/dt)]);
    k=k+round(numFrame/dt);
    toc
    
end

end


