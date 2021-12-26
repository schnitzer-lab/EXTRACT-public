function c = get_pixel(im)
h = make_figure(0.5, 0.5);
imagesc(im); axis image; colormap bone;axis off;
title('double click on a pixel')
[x, y] = getpts(h);
c = [x, y];
close(h);
