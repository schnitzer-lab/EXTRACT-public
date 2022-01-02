function denoisingSVDh5(input)

[filename,datasetname] = parse_movie_name(input);

filename  = filename(1:end-3);

hinfo=h5info([filename '.h5']);
totalnum = hinfo.Datasets.Dataspace.Size(3);
nx = hinfo.Datasets.Dataspace.Size(1);
ny = hinfo.Datasets.Dataspace.Size(2);
numFrame = 1000;


outputfilenameSVD = [filename '_SVD_denoised'];

if isfile([outputfilenameSVD '.h5'])
    delete([outputfilenameSVD '.h5']);
end

try
h5create([outputfilenameSVD '.h5'],datasetname,[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,numFrame]);
catch
h5create([outputfilenameSVD '.h5'],datasetname,[nx ny totalnum],'Datatype','single','ChunkSize',[nx,ny,round(numFrame/2)]);
end


windowsize = min(totalnum, numFrame);

startno = [1:windowsize:totalnum];

if numel(startno) >1 
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

disp(sprintf('%s: Running SVD denoising split into %s movies', datestr(now),num2str(numel(startno)) ))

for i=1:numel(startno)
    % parfor can even improve, but h5write is too slow thus missing data
    disp(sprintf('\t %s: Processing %s/%s movies ', datestr(now),num2str(i),num2str(numel(startno))))
    data = single(h5read([filename '.h5'],datasetname,[1,1,startno(i)],[nx,ny,perframes(i)]));
    
    denoised_SVD = denoisingSVD(single(data));
    
    
    h5write([outputfilenameSVD '.h5'],datasetname,single(denoised_SVD),[1,1,startno(i)],[nx,ny,size(data,3)]);
    
end

outputfilenameSVD = [outputfilenameSVD '.h5'];
disp(sprintf('%s: Denoising finished ', datestr(now)))
end
