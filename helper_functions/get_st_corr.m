function [st_corrs, t_maxes_in_active_regions] = get_st_corr(M, im, trace, ...
    avg_radius, visualize)

    if nargin < 5 || isempty(visualize)
        visualize = 0;
    end
    
    if sum(im(:)) == 0
        st_corrs = 0;
        t_maxes_in_active_regions = 0;
        return;
    end
    
    im_threshold = 0.2;  % normalized to 1
    im_extension = avg_radius;  % Pixels
    t_treshold = 0.3;  % Normalized to trace maximum
    active_period_lower_limit = 5;  % Frames
    t_medfilt_span = 5;  % Frames

    % Smooth trace
    trace = medfilt1(trace, t_medfilt_span);
    % Get x-y ranges
    [x_range, y_range] = get_image_xy_ranges(im> im_threshold, im_extension);
    x_range = x_range(1):x_range(2);
    y_range = y_range(1):y_range(2);
    len_xy_range = length(y_range) * length(x_range);
    % Mean subtract and flatten cell image
    s = im(y_range, x_range);
    s = s(:);
    % Normalize image
    sz = zscore(s, 1) / sqrt(length(s));
    % Get active periods
    active_frames = get_active_frames(trace > t_treshold * max(trace), 2);
    n_active_frames = size(active_frames, 1);

    st_corrs = [];
    snapshots = [];
    t_maxes_in_active_regions = [];
   
    for i = 1:n_active_frames
        active_range = active_frames(i, 1):active_frames(i, 2);
        % Discard periods shorter than certain # of frames
        if length(active_range) < active_period_lower_limit
            continue;
        end
        t_small = trace(active_range);
        % normalize active trace
        tz_small = zscore(t_small, 1) / sqrt(length(active_range));
        % Take a temporal slice of the movie
%         Mdd = Md(:, active_range);
        M_small = M(y_range, x_range, active_range);
        Mdd = reshape(M_small,len_xy_range, length(active_range));
        s_corr = Mdd * tz_small';
        s_corr = zscore(s_corr, 1) / sqrt(len_xy_range);
        st_corr = sz' * s_corr; 
        st_corrs(end+1) = st_corr; %#ok<*AGROW>
        t_maxes_in_active_regions(end+1) = max(t_small);
        if visualize
            snapshot = Mdd * tz_small';
            snapshots = [snapshots, snapshot];
        end
    end
    
    if visualize
        snapshots = reshape(snapshots, length(y_range), length(x_range), size(snapshots, 2));
        num_disp = min(5, length(st_corrs));
        subplot(1, num_disp+1, 1);
        imagesc(im(y_range, x_range)); axis image;
        for i  =1:num_disp
            subplot(1, num_disp + 1, i + 1);
            imagesc(snapshots(:, :, i)); axis image;
            title(st_corrs(i));
        end
    end
end
    

    
  