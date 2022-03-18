function mask = get_circular_mask(M)
% Get circular mask for movies with GRIN lens
% Mask radius is computed automatically based on an intensity threshold

    im = max(M, [], 3);
    [h, w] = size(im);
    xlen = 0.4;
    ylen = 0.5;
    hf = figure('units','normalized','position',[0.5-xlen/2 0.5-ylen/2 xlen ylen]);
    imagesc(im); axis image; colormap bone;
    title("Draw a circular mask, double-click on it when done:")
    
    % Check version
    v =version('-release');
    v1 = str2double(v(1:end-1));
    v2 = v(end);
    if v1>2018 || (v1==2018 && strcmpi(v2, 'b'))
        new_matlab = true;
    else
        new_matlab = false;
    end

    if new_matlab       
        circle = drawcircle(gca, 'color', 'r', 'linewidth', 2, 'Facealpha', 0.05);
        pos = wait_func(circle);
        radius = circle.Radius;
        centers = circle.Center;
        [cx, cy] = meshgrid(1:w, 1:h);
        dist_matrix = sqrt((cy - centers(2)).^2 + (cx - centers(1)).^2);
        mask = dist_matrix < radius;
    else
        circle = imellipse(gca);
        pos = wait(circle);
        mask = poly2mask(pos(:, 1), pos(:, 2), h, w);
    end
    
    close(hf);
    fprintf('Mask done! \n');
    
    
    % Wait until double-clicked
    function pos = wait_func(roi)
        % Listen for mouse clicks on the ROI
        l = addlistener(roi,'ROIClicked',@clickCallback);
        % Block program execution
        uiwait;
        % Remove listener
        delete(l);
        % Return the current position
        pos = roi.Position;
    end

    % Resume if double-clicked
    function clickCallback(~,evt)
        if strcmp(evt.SelectionType,'double')
            uiresume;
        end
    end

end