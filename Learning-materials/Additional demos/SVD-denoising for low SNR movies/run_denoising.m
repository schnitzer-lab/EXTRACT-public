
%Enter path and filename info here
filename = 'example';
datasetname = '/Data';

%Enter the total number of frames, frames per partition, as well as fov info. numFrame should exactly divide totalnum
totalnum = ;
nx = ;
ny = ;
numFrame = ;


outputfilename = [filename '_denoised'];

h5create([outputfilename '.hdf5'],datasetname,[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,numFrame]);
%h5create([filename '_residual' '.hdf5'],datasetname,[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,numFrame]);


for i=1:numFrame:totalnum
    fprintf('Running %i out of %i parts',((i-1)/numFrame)+1,totalnum/numFrame);
    data = h5read([filename '.hdf5'],datasetname,[1,1,i],[nx,ny,numFrame]);
    
    %
    
    timeA = tic;
    [movie_out, U, V] = denoisingSVD(data);
    
    toc(timeA)
    
   
    
    h5write([outputfilename '.hdf5'],datasetname,single(movie_out),[1,1,i],[nx,ny,numFrame]);
    
end




