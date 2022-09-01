function plot_cellmap(ims,max_im,color)
    textfontsize = 16;    
    [h,w] = size(max_im);
    clim = [quantile(max_im(:), 0.2), quantile(max_im(:), 0.999)];
    imagesc(max_im,clim);%, [0, 0.2]);
    axis image;
    axis off
    colormap bone;
    
    hold on;
    plot_cells_overlay(ims,color,1);
    
    for idx = 1:10
        im = ims(:,:,idx);
        im = im / sum(im(:));  % make it sum to one
        x_center = sum((1:w) .* sum(im, 1));
        y_center = sum((1:h)' .* sum(im, 2));
        text(double(x_center), double(y_center), num2str(idx), 'FontSize', textfontsize, 'Color', [0 0 0], 'FontWeight', 'bold');
    end
    hold off;
    axis off

drawnow;    



end