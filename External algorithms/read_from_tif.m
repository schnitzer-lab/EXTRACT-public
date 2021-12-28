function M = read_from_tif(s,startno,nt)

tiff_info = imfinfo(s);
nx = tiff_info(1).Height;
ny = tiff_info(1).Width;

if nargin <2
    startno =1;
    nt = size(tiff_info, 1);
end



M = single(zeros(nx,ny,nt));

for ii = 1 : nt
    n_frame = ii - 1 + startno;
    M(:,:,ii) = single(imread(s, n_frame));
end

end