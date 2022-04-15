function view_movie(M, varargin)
% Displays the frames of a movie matrix M [height x row x num_frames]
max_im = max(M,[],3);
movie_clim = quantile(max_im(:),[0 0.90]);
h_trace = [];
time_offset = 0;
cellmap_overlay = 0;
rescale_each_frame = false;
pause_time = 0;
for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case 'color_map'
                color_map = varargin{k+1};
            case 'ims'
                cellmap_overlay = 1;
                ims = varargin{k+1};
            case 'im_colors'
                colors = varargin{k+1};
            case 'h_trace'
                h_trace = varargin{k+1};
            case 'time_offset'
                time_offset = varargin{k+1};
            case 'ax'
                ax = varargin{k+1};
            case 'pause_time'
                pause_time = varargin{k+1};
        end
    end
end

% Set colormap if not given
if ~exist('color_map', 'var')
    color_map = bone;
end
% Make new figure & axes if axes is not given
if ~exist('ax', 'var')
    h_fig = figure();
    ax = axes(h_fig, 'Position', [0, 0, 1,0.95]);
end
num_frames = size(M,3);

if ~isempty(movie_clim) % If CLim is provided, use it
    h = imagesc(ax, M(:,:,1), movie_clim);
else
    if (rescale_each_frame || isa(M, 'uint16'))
        % Raw movies (e.g. uint16) are rescaled by default
        h = imagesc(ax, M(:,:,1));
    else % Otherwise, use common CLim scaling
        movie_clim = compute_movie_scale(M);
        h = imagesc(ax, M(:,:,1), movie_clim);
    end
end
% Image is the last object, send it to back in case it isn't 
% (in case there were objects before raster)
ax_objects = get(ax,'children');
set(ax, 'Children', circshift(ax_objects, -1));

axis(ax, 'off');
axis(ax, 'image');
colormap(ax, color_map);


if cellmap_overlay
    hold(ax, 'on');
    %plot_cell_images(ax, ims, colors, colors);
    plot_cells_overlay(ims,colors,[]);
    hold(ax, 'off');
end

if ~isempty(h_trace)
    ax_trace = get(h_trace, 'parent');
    trace_data = h_trace.YData;
    ylims = get(ax_trace, 'ylim');
    hold(ax_trace, 'on');
    h_progress = plot(ax_trace, ([1 1]+time_offset), ylims, 'k'); % Time indicator
    h_dot = plot(ax_trace, 1 + time_offset, trace_data(1+ time_offset), 'or',...
        'MarkerFaceColor', 'r', 'MarkerSize', 12);
    hold(ax_trace, 'off');
end


for k = 1:num_frames
    title(ax, sprintf('Frame %d of %d', k, num_frames));
    m = M(:,:,k);
    set(h, 'CData', m);
    % If given, plot progress bar on trace
    if ~isempty(h_trace)
        set(h_progress, 'XData',[1, 1] * (k + time_offset));
        set(h_dot, 'XData', (k + time_offset),...
            'YData', trace_data(k + time_offset));
    end
    pause(pause_time)
    drawnow;
end

% Delete dot and time indicator
if ~isempty(h_trace)
    delete(h_progress);
    delete(h_dot);
end

    function clim = compute_movie_scale(M)
    % Compute an appropriate viewing scale (CLim) for the provided movie

    [height, width, ~] = size(M);
    maxVec = reshape(max(M,[],3), height*width, 1);
    minVec = reshape(min(M,[],3), height*width, 1);
    quantsMax = quantile(maxVec,[0.85,0.87,0.9,0.93,0.95]);
    quantsMin = quantile(minVec,[0.85,0.87,0.9,0.93,0.95]);

    clim = [mean(quantsMin) mean(quantsMax)];
    clim_range = clim(2)-clim(1);
    clim = clim + 0.1*clim_range*[-1 1];
    end

end
