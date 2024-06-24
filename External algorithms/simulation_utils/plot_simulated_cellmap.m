function plot_simulated_cellmap(ims,max_im,im_g,color_gt,color_ex)
    textfontsize = 16;
    textcolor = 'w';
    xlen = 0.5;
    ylen = 0.5;
    hf = figure('units','normalized','position',[0.5-xlen/2 0.5-ylen/2 xlen ylen]);
    set(hf,'renderer','painters')
    
    [h,w] = size(max_im);
    clim = [quantile(max_im(:), 0.2), quantile(max_im(:), 0.999)];
    imagesc(max_im,clim);%, [0, 0.2]);
    axis image;
    axis off
    colormap bone;
    
    hold on;
    plot_cells_overlay(ims,color_gt,3,0.5);
    for idx = 1:size(im_g,3)
        im = im_g(:,:,idx);
        im = im / sum(im(:));  % make it sum to one
        x_center = sum((1:w) .* sum(im, 1));
        y_center = sum((1:h)' .* sum(im, 2));
        text(double(x_center), double(y_center), num2str(idx), 'FontSize', textfontsize, 'Color', [0 0 0], 'FontWeight', 'bold');
        plot_cells_overlay(reshape(im,size(im,1),size(im,2),1),color_ex,3,0.5);
    end
    hold off;
    axis off

drawnow;    

end