function plot_components(im, T, title_val)
    do_title = false;
    if exist('title_val', 'var')
        do_title = true;
    end
    for i = 1:size(T, 1)
        subplot(3, 1, [1, 2]);
        imagesc(im(:, :, i));
        axis image;
        colormap jet;
        if do_title
            title(sprintf('#%d, val: %.4f', i, title_val(i)));
        else
            title(i);
        end
        subplot(3, 1, 3);
        plot(T(i, :));
        pause;
    end
end