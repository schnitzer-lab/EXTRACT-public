function cell_check(output, M)
    
    active_learning = true;
    if ~isfield(output.config, 'fast_cellcheck') 
        fast_cellcheck = 0;
    else
        fast_cellcheck = output.config.fast_cellcheck;
        if fast_cellcheck == 1
            active_learning = 0;
        end
    end
    % Settings
    
    default_n_active_frames = 10;

    h_trace = [];
    x_current = [];
    y_current = [];
    handle_snapshots = cell(1, default_n_active_frames + 1);
    idx_next_cell = NaN;
    idx_current_cell = 2;
    idx_previous_cell = 1;
    display_bad_cells = 0;
    h_cellmap = [];
    color_good = [0, 1, 0];
    color_bad = [1, 0, 0];
    color_unlabeled = [0.7, 0.8, 0.85];
    color_current = [0, 0.5, 0.9];
    face_alpha = 0.1;
    default_colormap = flipud(brewermap(64, 'rdgy'));
    h_neighbor_outlines = [];
    score_lower_threshold = 0;
    score_upper_threshold = 1; 
    
    % Get output (extract data if it's a mat file)
    [output, output_handle] = parse_output(output);
    
    % Get cellcheck struct
    
    [is_attr_bad,metrics,is_elim]=get_cellcheck_features(output);
    output.config = get_defaults(output.config);
    
    
    
    ims = output.spatial_weights;
    traces = output.temporal_weights';
    summary_image = output.info.summary_image;
    features = metrics';
    
    num_cells = size(ims, 3);
    extract_labels = zeros(1, size(ims, 3));

    user_labels = zeros(size(extract_labels));
    labels = zeros(size(extract_labels));
    update_labels;
    
    cellcheck = struct('ims', ims,...
        'traces', traces,...
        'is_attr_bad', is_attr_bad);

    if isfield(output, 'already_accepted')
        cellcheck.ims_accepted = output.already_accepted;
    end

    if isfield(output, 'neighbor_cells')
        cellcheck.ims_surround = output.neighbor_cells;
    end
    
    % Train initial scores
    extract_scores = zeros(num_cells, 1);
    [guess_good, guess_bad] = guess_labels_from_metrics(metrics);
    ml_labels = zeros(num_cells, 1, 'single');
    ml_labels(guess_good) = 1;
    ml_labels(guess_bad) = -1;
    update_scoring_model;
    
    % Update extract labels per confidences
    update_extract_labels;
    
    % Prepare graphics containers
    screen_size = get(0,'screensize');
    figure_pos = [screen_size(1)*1.1, screen_size(2)*1.1,...
        screen_size(3)*0.8, screen_size(4)*0.8];
    xy_ratio = screen_size(3) / screen_size(4);
    ex = 0.02;
    main_fig = uifigure('Position', figure_pos);
    panel_snapshot = uipanel(main_fig, 'Position', norm2pix([0, 0.2, 1, 0.1], figure_pos),...
        'BorderType', 'none');
    ax_cellmap = make_axes(main_fig, 0, 0.3, 0.4, 0.4 * xy_ratio, ex);
    ax_cell_trace = make_axes(main_fig, 0, 0, 1, 0.2, ex);
    ax_snippet = make_axes(main_fig, 0.7, 0.35, 0.3, 0.3 * xy_ratio, ex);
    axis(ax_snippet, 'off');
    
    % Text for selecting number of frames around the event to display
    text_time_ext_before = uieditfield(main_fig, 'Numeric', 'value', 10, ...
        'Position', subpos([0.852, 0.33, 0.02, 0.02], figure_pos));
    text_time_ext_after = uieditfield(main_fig, 'Numeric', 'value', 30, ...
        'Position', subpos([0.852, 0.31, 0.02, 0.02], figure_pos));
    uilabel(main_fig, 'text', 'Show',...
        'Position', subpos([0.83, 0.33, 0.02, 0.02], figure_pos));
    uilabel(main_fig, 'text', 'Show',...
        'Position', subpos([0.83, 0.31, 0.02, 0.02], figure_pos));
    uilabel(main_fig, 'text', 'frames before chosen time',...
        'Position', subpos([0.875, 0.33, 0.1, 0.02], figure_pos));
    uilabel(main_fig, 'text', 'frames after chosen time',...
        'Position', subpos([0.875, 0.31, 0.1, 0.02], figure_pos));
    
    % Cell selection
    pos_panel_cell_select = norm2pix([0.4, 0.85, 0.1, 0.1], figure_pos);
    panel_cell_select = uipanel(main_fig, 'position', pos_panel_cell_select, ...
        'Bordertype', 'none');
    pos_panel_cell_stats = norm2pix([0.4, 0.35, 0.2, 0.35], figure_pos);
    panel_cell_stats = uipanel(main_fig, 'position', pos_panel_cell_stats, ...
        'Bordertype', 'none');
    
    checkbox_display_bad = uicheckbox(main_fig, 'text', 'show bad cells',...
        'value', 0, 'position', norm2pix([0.52, 0.94, 0.1, 0.02], figure_pos));
    add_callback(checkbox_display_bad, 'ValueChangedFcn', @toggle_bad_cell_display);
    checkbox_autolabel = uicheckbox(main_fig, 'text', 'Suggest hard cells',...
        'value', 0, 'position', norm2pix([0.52, 0.92, 0.1, 0.02], figure_pos));
    
    
    % Save & Load buttons
    button_save = uibutton(main_fig, 'text', 'save data',...
      'position', norm2pix([0.55, 0.40, 0.15, 0.05], figure_pos));

    add_callback(button_save, 'ButtonPushedFcn', @save_data);
    
    button_zoom = uibutton(main_fig, 'text', 'zoom to current cell',...
         'position', norm2pix([0.45, 0.30, 0.05, 0.05], figure_pos));
    add_callback(button_zoom, 'ButtonPushedFcn', @draw_current_region);
    
%     button_load = uibutton(main_fig, 'text', 'load',...
%          'position', norm2pix([0.55, 0.82, 0.05, 0.05], figure_pos));
%     add_callback(button_load, 'ButtonPushedFcn', @load_labels);
    
    % Cell selection
    uilabel(panel_cell_select, 'text', 'Go to cell:',...
        'Position', subpos([0, 0.5, 4/7, 0.25], pos_panel_cell_select));
    % Suppress warning (seen in Matlab 2018b) with slider height
    warning('off', 'MATLAB:ui:Slider:fixedHeight');
    slider_cell = uislider(panel_cell_select, 'limits', [1, num_cells],...
        'Position', subpos([0.07, 0.9, 0.86, 0.1], pos_panel_cell_select),...
        'MajorTicks', [], 'MinorTicks', []);
    add_callback(slider_cell, 'ValueChangedFcn', @set_current_cell_from_slider_cell);
    text_cell = uieditfield(panel_cell_select, 'Numeric', 'value', 1, ...
        'Position', subpos([4/7, 0.5, 3/7, 0.25], pos_panel_cell_select));
    add_callback(text_cell, 'ValueChangedFcn', @set_current_cell);
    button_prev_cell = uibutton(panel_cell_select, 'text', {'prev', '<<'}, ...
        'Position', subpos([0, 0.05, 0.5, 0.4], pos_panel_cell_select), ...
        'FontColor', 'w', 'FontWeight', 'bold', 'BackgroundColor', [0, 0.4, 0.9]);
    add_callback(button_prev_cell, 'ButtonPushedFcn', @set_current_cell_from_button_prev);
    button_next_cell = uibutton(panel_cell_select, 'text', {'next', '>>'}, ...
        'Position', subpos([0.5, 0.05, 0.5, 0.4], pos_panel_cell_select),...
        'FontColor', 'w', 'FontWeight', 'bold', 'BackgroundColor', [0, 0.4, 0.9]);
    add_callback(button_next_cell, 'ButtonPushedFcn', @set_current_cell_from_button_next);
    
    % Cell annotation
    uilabel(main_fig, 'text', ' Manually label:',...
        'Position', norm2pix([0.4, 0.805, 0.2, 0.02], figure_pos), ...
        'Fontweight', 'bold', 'FontSize', 14,...
        'horizontalalignment', 'center');
    button_good_cell = uibutton(main_fig, 'text', 'Cell', ...
        'Position', norm2pix([0.4+0.2/3, 0.7, 0.2/3, 0.1], figure_pos),...
        'FontColor', 'w', 'FontWeight', 'bold', 'BackgroundColor', [0, 0.8, 0]);
    add_callback(button_good_cell, 'ButtonPushedFcn', @label_as_good);
    button_bad_cell = uibutton(main_fig, 'text', 'Not a cell', ...
        'Position', norm2pix([0.4, 0.7, 0.2/3, 0.1], figure_pos),...
        'FontColor', 'w', 'FontWeight', 'bold', 'BackgroundColor', [0.8, 0, 0]);
    add_callback(button_bad_cell, 'ButtonPushedFcn', @label_as_bad);
    button_unlabeled_cell = uibutton(main_fig, 'text', 'Unlabeled', ...
        'Position', norm2pix([0.4+0.4/3, 0.7, 0.2/3, 0.1], figure_pos),...
        'FontColor', 'w', 'FontWeight', 'bold', 'BackgroundColor', color_unlabeled);
    add_callback(button_unlabeled_cell, 'ButtonPushedFcn', @label_as_unlabeled);
    
    % Cell statistics
    uilabel(panel_cell_stats, 'text', sprintf(' Not a cell if score < :'),...
        'Position', subpos([0, 0.92, 0.5, 0.05], pos_panel_cell_stats),...
        'fontweight', 'bold', 'fontcolor', [0.8, 0, 0]);
    slider_score_lower = uislider(panel_cell_stats, 'limits', [0, 0.5],...
        'Position', subpos([0, 0.9, 0.45, 0.05], pos_panel_cell_stats),...
         'MinorTicks', [], 'Value', score_lower_threshold, ...
         'Fontsize', 10);
    uilabel(panel_cell_stats, 'text', sprintf(' Cell if score > :'),...
        'Position', subpos([0.6, 0.92, 0.5, 0.05], pos_panel_cell_stats),...
        'fontweight', 'bold', 'fontcolor', [0, 0.7, 0]);
    slider_score_upper = uislider(panel_cell_stats, 'limits', [0.5, 1],...
        'Position', subpos([0.55, 0.9, 0.45, 0.05], pos_panel_cell_stats),...
         'MinorTicks', [], 'Value', score_upper_threshold, ...
         'Fontsize', 10);
    add_callback(slider_score_lower, 'ValueChangedFcn', @set_score_thresholds);
    add_callback(slider_score_upper, 'ValueChangedFcn', @set_score_thresholds);
    
    % General stats
    uilabel(panel_cell_stats, 'text', ' Cell annotation statistics (# cells):',...
        'Position', subpos([0, 0.73, 1, 0.07], pos_panel_cell_stats), ...
        'Fontweight', 'bold');
    ypos_overall = [0.63, 0.1];
    ypos_extract = [0.56, 0.05];
    ypos_user = [0.5, 0.05];
    uilabel_stats_overall = update_population_stats(ypos_overall, labels, ' Overall:');
    uilabel_stats_extract = update_population_stats(ypos_extract, extract_labels, ' EXTRACT:');
    uilabel_stats_user = update_population_stats(ypos_user, user_labels, ' User:');
    % cell specific stats
    uilabel(panel_cell_stats, 'text', ' Current cell summary:',...
        'Position', subpos([0, 0.4, 1, 0.07], pos_panel_cell_stats), ...
        'Fontweight', 'bold');
    label_cell_report = uilabel(panel_cell_stats, 'text', '',...
        'Position', subpos([0, 0, 1, 0.4], pos_panel_cell_stats));
    update_cell_report;
%     add_callback(slider_cell, 'ValueChangedFcn', @set_current_cell_from_slider_cell);
    
%     text_cell = uieditfield(panel_cell_select, 'Numeric', 'value', 1, ...
%         'Position', subpos([4/7, 0.5, 3/7, 0.25], pos_panel_cell_select));
%     add_callback(text_cell, 'ValueChangedFcn', @set_current_cell);
%     button_prev_cell = uibutton(panel_cell_select, 'text', {'prev', '<<'}, ...
%         'Position', subpos([0, 0.05, 0.5, 0.4], pos_panel_cell_select), ...
%         'FontColor', 'w', 'FontWeight', 'bold', 'BackgroundColor', [0, 0.4, 0.9]);
%     add_callback(button_prev_cell, 'ButtonPushedFcn', @set_current_cell_from_button_prev);
%     button_next_cell = uibutton(panel_cell_select, 'text', {'next', '>>'}, ...
%         'Position', subpos([0.5, 0.05, 0.5, 0.4], pos_panel_cell_select),...
%         'FontColor', 'w', 'FontWeight', 'bold', 'BackgroundColor', [0, 0.4, 0.9]);
%     add_callback(button_next_cell, 'ButtonPushedFcn', @set_current_cell_from_button_next);

    % Plot cellmap
    plot_cellmap;

    % Get neighbors for each cell
    
    cellcheck.neighbors = get_all_neighbors(cellcheck);
    set_score_thresholds;
    
    if checkbox_autolabel.Value == 1
        set(text_cell, 'value', idx_next_cell);
    end
    
    % Load user labels if they exist
    load_labels;
    % View the selected cell
    set_current_cell;
   
%---------------------------------------------------------
%--------///////// functions //////////--------------
%-------------------------------------------------

    function update_cell_report
        extract_verdict = extract_labels(idx_current_cell);
        user_verdict = user_labels(idx_current_cell);
        verdict = labels(idx_current_cell);
        line1 = sprintf('This is %s:\n \tEXTRACT:%s\n\t User:%s\n',...
            get_label_str(verdict, true),...
            get_label_str(extract_verdict, false),...
            get_label_str(user_verdict, false));
        confidence = extract_scores(idx_current_cell);
        line2 = sprintf('EXTRACT score: %.2f\n', confidence);
        line3 = sprintf('Elimination reason(s): %s', get_bad_metrics);
        set(label_cell_report, 'text', sprintf('%s %s %s', line1, line2, line3),...
            'BackgroundColor', max(0.5, label_to_color_mapping(verdict)));
        
        function label = get_label_str(verdict, fancy)
            if verdict == 1
                label = 'cell';
                pre = 'a ';
                sf = '';
            elseif verdict == 0 || verdict ==-2
                label = 'unlabeled';
                pre = 'an ';
                sf = ' cell';
            elseif verdict == -1
                label = 'not a cell';
                pre = '';
                sf = '';
            end
            if fancy
                label = [pre, label, sf];
            end
        end
        
        function out = get_bad_metrics
            attrs = {'''duplicate''', '''duplicate''', '''zero trace''',...
                '''bad looking trace''', '''cell too small''',...
                '''cell too large''' , '''image looks bad''' , ...
                '''image is too eccentric''', '''activity doesn''t match movie''',...
                };
            bad_metrics = find(cellcheck.is_attr_bad(:, idx_current_cell));
            out = '';
            for i = 1:length(bad_metrics)
                out = sprintf('%s \n\t%s', out, attrs{bad_metrics(i)});
            end
            if isempty(out)
                out = 'None';
            end
        end
    end

    function update_stats_all
        uilabel_stats_overall = update_population_stats(uilabel_stats_overall, labels);
        uilabel_stats_extract = update_population_stats(uilabel_stats_extract, extract_labels);
        uilabel_stats_user = update_population_stats(uilabel_stats_user, user_labels);
    end

    function h_stats = update_population_stats(h_stats, labels, dscp_txt)
        if ~iscell(h_stats)
            % pos given instead of handles cell array, create them with given
            % pos:
            ypos = h_stats;
            colors = {color_good, color_unlabeled, color_bad};
            h_stats = cell(1, 3);
            if exist('dscp_txt', 'var')
                pos = subpos([0, ypos(1), 1/4, ypos(2)],...
                    get(panel_cell_stats, 'Position'));
                uilabel(panel_cell_stats, 'Position', pos, ...
                    'FontWeight', 'Bold', 'Fontsize', 10, 'text', dscp_txt);
            end
            for i = 1:3
                % stats label
                pos = subpos([1/4*i, ypos(1), 1/4, ypos(2)],...
                    get(panel_cell_stats, 'Position'));
                h = uilabel(panel_cell_stats, 'Position', pos, ...
                    'BackgroundColor', colors{i}, 'FontColor', 'k',...
                    'FontWeight', 'Bold', 'Fontsize', 10,...
                    'HorizontalAlignment', 'center');
                h_stats{i} = h;
            end
        end
        get_stats = @(labels)  [sum(labels==1), sum(labels==0), sum(labels==-1)];
        stats = get_stats(labels);
        x_len_norm = stats / sum(stats);
        x_start_norm = cumsum(x_len_norm);
        x_start_norm = [0, x_start_norm(1:2)];
        % Get props
        poss = cell(1, 3);
        for i = 1:3
            poss{i} = get(h_stats{i}, 'Position');
        end
        % Get global limits
        x_start = poss{1}(1);
        x_total_len = poss{3}(1) + poss{3}(3) - x_start;
        % Set props
        for i = 1:3
            pos = poss{i};
            pos(1) = x_start + x_start_norm(i) * x_total_len;
            pos(3) = x_total_len * x_len_norm(i);
            set(h_stats{i}, 'Position', pos, 'text', sprintf('%d', stats(i)));
        end    
    end

    function plot_cellmap
        % Plot cellmap raster
        imagesc(ax_cellmap, summary_image);
        colormap(ax_cellmap, default_colormap);
        axis(ax_cellmap, 'equal', 'off');
        hold(ax_cellmap, 'on');
        if isfield(cellcheck, 'ims_surround')
            plot_cell_images(ax_cellmap, cellcheck.ims_surround,...
            [0,0,1], [0,0,1], 'callback_fn', [],'display_thr', 0.05);
        end
        if isfield(cellcheck, 'ims_accepted')
            plot_cell_images(ax_cellmap, cellcheck.ims_accepted,...
            [0,1,0], [0,1,0], 'callback_fn', [],'display_thr', 0.05);
        end
        % Set colors for cells
        colors =label_to_color_mapping(labels);
        h_cellmap = plot_cell_images(ax_cellmap, cellcheck.ims,...
            colors, colors, 'callback_fn', @set_current_cell_from_cellmap,'display_thr', 0.05);


        
        hold(ax_cellmap, 'off');
        % Set visibility of bad cells according to uicheckbox
        toggle_bad_cell_display;
    end

    function update_one_cell(idx_cell)
        h_cell = h_cellmap{idx_cell};
        lbl = labels(idx_cell);
        if idx_cell == idx_current_cell
            f_alpha = 1;
            clr = color_current;
        else
            clr = label_to_color_mapping(lbl);
            f_alpha = face_alpha;
        end
        h_cell.EdgeColor = clr;
        h_cell.FaceColor = clr;
        h_cell.FaceAlpha = f_alpha;
        h_cell.Visible = display_bad_cells | (lbl ~= -1);
    end

    function trace_click_callback(~, eo)
    % User clicked on trace (will play activity in active region around chosen timepoint)
        idx_t = round(eo.IntersectionPoint(1));
        play_snippet_in_active_region(idx_t);
    end

    function set_current_cell_from_button_prev(varargin)
        set(text_cell,'Value',idx_current_cell-1);
        set_current_cell;
    end

    function set_current_cell_from_button_next(varargin)
        set(text_cell,'Value',decide_next_cell);
        set_current_cell;
    end

    function set_current_cell_from_slider_cell(~, ~)
        val = round(get(slider_cell,'Value'));
        set(text_cell,'Value',val);
        set_current_cell;
    end

    function save_data(varargin)
        output.extract_labels = extract_labels;
        output.user_labels = user_labels;
        output.labels = labels;
        output_handle.output = output;
    end

    function load_labels(varargin)
        if isfield(output, 'user_labels')
            user_labels = output.user_labels;
            update_labels;
            % Re-train labels per user labels
            if active_learning
                is_user_labeled = user_labels~=0;
                ml_labels(is_user_labeled) = user_labels(is_user_labeled);
                update_scoring_model;
            end
            % Update cellmap
            for i = 1:num_cells
                update_one_cell(i);
            end
            % Update stats
            update_stats_all;
            % Update cell report
            update_cell_report;
        end
    end

    function set_current_cell_from_cellmap(h_cell, ~)
        % User clicked on cellmap    
        cell_id = h_cell.DisplayName;
        cell_id = str2double(cell_id);
        set(text_cell,'Value',cell_id);
        set_current_cell;
    end

    function set_current_cell(varargin)
    % Main function to set current cell, by looking at the textbox
        % Enforce valid value
        val = max(1, min(num_cells, round(get(text_cell,'Value'))));
        set(text_cell,'Value',val);
        % Don't do anything if value hasn't changed
        if val == idx_current_cell
            return;
        end
        % Update current & previous cell indices and cellmap
        idx_previous_cell = idx_current_cell;
        idx_current_cell = val;
        update_one_cell(idx_previous_cell);
        update_one_cell(idx_current_cell);
        xlim(ax_cellmap,'auto')
        ylim(ax_cellmap,'auto')
        drawnow;
        % Update slider
        set(slider_cell,'Value',idx_current_cell);
        % Get active region & M
        [x_current, y_current] = get_active_region(idx_current_cell);
        % Update cell report
        update_cell_report;
        % Plot cell trace
        plot_trace;
        % Plot cell image + event snapshots
        plot_event_snapshots_with_neighbors;
        clear_axes(ax_snippet);
    end

    function draw_current_region(varargin)
        im_n=cellcheck.ims(:,:,idx_current_cell);
        [h,w]=size(im_n);
        im_n = im_n / sum(im_n(:));  % make it sum to one
        x_center = sum((1:w) .* sum(im_n, 1));
        y_center = sum((1:h)' .* sum(im_n, 2));
        avg_radius=output.config.avg_cell_radius;
        xlim(ax_cellmap,[x_center-3*avg_radius,x_center+3*avg_radius]);
        ylim(ax_cellmap,[y_center-3*avg_radius,y_center+3*avg_radius]);
    end



    function next_cell = decide_next_cell
        if checkbox_autolabel.Value == 1
            next_cell = idx_next_cell;
        else
            % Go to next unlabeled cell
            next_cell = idx_current_cell;
            while next_cell < num_cells
                next_cell = next_cell + 1;
                if user_labels(next_cell) == 0
                    break
                end
            end
        end
    end

    function label_as_good(varargin)
        user_labels(idx_current_cell) = 1;
        update_labels;
        
        % If active lerning is on, then update predictive model
        if active_learning
            ml_labels(idx_current_cell) = 1;
            update_scoring_model;
            update_labels;
        end
        
        if fast_cellcheck == 0
            update_extract_labels;        
            update_stats_all;
        end
        set_current_cell_from_button_next;
    end

    function label_as_bad(varargin)
        user_labels(idx_current_cell) = -1;
        update_labels;
        
        % If active lerning is on, then update predictive model
        if active_learning
            ml_labels(idx_current_cell) = -1;
            update_scoring_model;
            update_labels;
        end
        
        if fast_cellcheck == 0
            update_extract_labels;        
            update_stats_all;
        end
        set_current_cell_from_button_next;
    end

    function label_as_unlabeled(varargin)
        user_labels(idx_current_cell) = -2;
        update_labels;
        
        % If active lerning is on, then update predictive model
        if active_learning
            update_scoring_model;
            update_labels;
        end
        
        if fast_cellcheck == 0
            update_extract_labels;        
            update_stats_all;
        end
        set_current_cell_from_button_next;
    end

    function set_score_thresholds(varargin)
        score_upper_threshold = slider_score_upper.Value;
        score_lower_threshold = slider_score_lower.Value;
        % Update extract_labels and labels
        update_extract_labels;
        update_labels;
        % Update cellmap
        for i = 1:num_cells
            update_one_cell(i);
        end
        % Update stats
        update_stats_all;
        % Update cell report
        update_cell_report;
            
    end
    
    function toggle_bad_cell_display(varargin)
        display_bad_cells = checkbox_display_bad.Value;
        % Set all bad cell handles to visible in cellmap
        idx_bad = find(labels == -1);
        for i = 1:length(idx_bad)
            idx_this = idx_bad(i);
            if display_bad_cells
                set(h_cellmap{idx_this}, 'visible', 'on');
            else
                set(h_cellmap{idx_this}, 'visible', 'off');
            end
        end
    end

    function update_scoring_model
        % In order to prevent circular logic in active learning, exclude
        % EXTRACT labels from overall labels 
        given_labels = user_labels;
        given_labels(is_elim) = -1;
        [idx_next_cell, extract_scores, ~] = ...
            ask_for_label(features, given_labels, ml_labels);
    end

    function plot_trace
        trace = cellcheck.traces(idx_current_cell, :);
        h_trace = plot(ax_cell_trace, trace, 'color', 'k', 'linewidth', 0.5, 'HitTest', 'off');
        % Addition of 1e-6 is to safeguard against zero traces
        ylims = [min(trace), max(trace)+1e-6];
        set(ax_cell_trace, 'color', 'none', 'ylim', ylims);
        add_callback(ax_cell_trace, 'ButtonDownFcn', @trace_click_callback);
    end
    

    function plot_event_snapshots_with_neighbors
        trace = h_trace.YData;
        % Don't plot if trace is zero
        if sum(trace) == 0
            return;
        end
        % Color for displaying text label in images and on event peaks
        text_color = [0.3, 0.5, 1];
        % Get active periods
        active_frames = get_active_frames(trace > 0.2 * max(trace), 2);
        % Transpose for convenience
        active_frames = active_frames';

        % Detect events and display N of them
        event_frames = detect_ca_events(trace, 0.5);
        
        n_active_frames = min([default_n_active_frames,...
            size(active_frames, 2), length(event_frames)]); % # of events to display
        
        event_frames = select_events(event_frames, n_active_frames);
        
        % Intersect active frames with chosen event times
        idx_active_frames = zeros(1, n_active_frames);
        for i = 1:n_active_frames
            idx = find(active_frames(:) <= event_frames(i), 1, 'last');
            [~, x] = ind2sub([2, size(active_frames, 2)], idx);
            idx_active_frames(i) = x;
        end
        % Filter out non-intersecting active frames 
        active_frames = active_frames(:, idx_active_frames);
        % Sort chronologically
        [~, idx_sort] = sort(active_frames(1, :));
        active_frames = active_frames(:, idx_sort);
        event_frames = event_frames(idx_sort);
        % Place dots on trace for active periods
        hold(ax_cell_trace, 'on');
        plot(ax_cell_trace, event_frames, trace(event_frames), 'og',...
            'MarkerFaceColor', 'g', 'MarkerSize', 5);
        % Put label text on active period peaks
        text_array = cell(1, n_active_frames);
        for i = 1:n_active_frames
            text_array{i} = num2str(i);
        end
        text(ax_cell_trace, event_frames+5, double(trace(event_frames)),...
            text_array, 'Fontsize', 12, 'Fontweight', 'bold', 'color', text_color);
        hold(ax_cell_trace, 'off');

        % Adjust width to accomodate cell image + snapshots
        axes_width = 1 / (1 + default_n_active_frames);
        % Plot cell image
        im = full(cellcheck.ims(y_current, x_current, idx_current_cell));
        [x_lims, y_lims] = get_image_xy_ranges(im> 0.2, 5);
        cell_image = im(y_lims(1):y_lims(2), x_lims(1):x_lims(2));
        % Create axes & image first time, update cdata in subsequent calls
        if isempty(handle_snapshots{1})
            ax = make_axes(panel_snapshot, 0, 0, axes_width, 1, 0);
            handle_snapshots{1} = imagesc(ax, cell_image); 
            axis(ax, 'image', 'off');
            colormap(ax, flipud(brewermap(64, 'rdbu')));
        else
            set(handle_snapshots{1}, 'CData', cell_image);
        end

        for i = 1:n_active_frames
            t_range = active_frames(1, i):active_frames(2, i);
            % Obtain the relevant movie portion
            M_small = get_movie(t_range);
            [hs, ws, ns] = size(M_small);
            M_small = reshape(M_small, hs*ws, ns);
            t_small = trace(t_range);
            % Subtract the mean
            t_small = smooth(t_small - mean(t_small), 5);
            % Get mean image as correlation of trace and movie
            mean_image = M_small * t_small;
            %smooth_images(mean_image, [h, w], 1, 0);
            % Rshape to 2d
            mean_image = reshape(mean_image, hs, ws);
            % Smooth
            mean_image = medfilt2(mean_image);
            % Convert to int
            mean_image = convert_to_int(mean_image);
            % Create axes & image first time, update cdata in subsequent calls
            if isempty(handle_snapshots{i+1})
                ax = make_axes(panel_snapshot, i*axes_width, 0, axes_width, 1, 0);
%                 set(ax, 'XLim', x_lims, 'YLim', y_lims);
                handle_snapshots{i+1} = imagesc(ax, mean_image);
                axis(ax, 'image', 'off');
                set(ax, 'CLim', get_clims(mean_image));
                colormap(ax, default_colormap);
            else
                ax = handle_snapshots{i+1}.Parent;
%                 set(ax, 'XLim', x_lims, 'YLim', y_lims);
                clear_accessories_in_axes(ax);
                set(handle_snapshots{i+1}, 'CData', mean_image);
                set(ax, 'CLim', get_clims(mean_image));
            end
            text(ax, x_lims(1), y_lims(1) + 2, num2str(i), 'Fontsize', 12,...
                'Fontweight', 'bold', 'color', [0, 1, 1]);
            show_content(ax);
            set(ax, 'visible', 'off');
                
            % Only draw if first snapshot, else copy objects
            if i == 1
                plot_neighbor_outlines(ax);
            else
                for j = 1:length(h_neighbor_outlines)
                    copyobj(h_neighbor_outlines{j}, ax);
                end
            end
            set(ax, 'XLim', x_lims, 'YLim', y_lims);
        end
        % Hide unused axes
        for i = n_active_frames+1:default_n_active_frames
            if ~isempty(handle_snapshots{i+1})
                ax = handle_snapshots{i+1}.Parent;
                hide_content(ax);
            end
        end
    end
    
    function plot_neighbor_outlines(ax)
        % Get images
        ims_local = full(cellcheck.ims(y_current, x_current, idx_current_cell));
        idx_neighbor = cellcheck.neighbors{idx_current_cell};
        % Skip bad cells according to bad cell display checkbox
        if ~isempty(idx_neighbor) && checkbox_display_bad.Value == 0
            idx_neighbor(labels(idx_neighbor)==-1) = [];
        end
        colors = {color_current};
        if ~isempty(idx_neighbor) 
            ims_neighbor = full(cellcheck.ims(y_current, x_current, idx_neighbor));
            ims_local = ...
                cat(3, ims_local, ims_neighbor);
            colors = [colors, label_to_color_mapping(labels(idx_neighbor))];
        end
        hold(ax, 'on');
        h_neighbor_outlines = plot_cell_images(ax, ims_local,  colors, colors,...
            'face_alpha', 0, 'display_thr', 0.05);
         hold(ax, 'off');
        % Edit properties of the current cell
        set(h_neighbor_outlines{1}, 'edgealpha', 0.7, 'linewidth', 3);
    end

    function play_snippet_in_active_region(idx_t)
        n = size(cellcheck.traces, 2);
        % Make sure idx_t is within allowed limit
        idx_t = max(1, min(n, idx_t));
        time_ext_before = get(text_time_ext_before,'Value');
        time_ext_after = get(text_time_ext_after,'Value');
        time_begin = max(1, idx_t - time_ext_before);
        time_end = min(n, idx_t + time_ext_after);
        time_range = time_begin:time_end;

        % Plot cell outlines
        ax_snippet.YDir = 'reverse';
        clear_axes(ax_snippet);
        for i = 1:length(h_neighbor_outlines)
            copyobj(h_neighbor_outlines{i}, ax_snippet);
        end
        hold(ax_snippet, 'on');
        M_current = get_movie(time_range);
        view_movie(M_current, 'time_offset', time_begin-1, ...
            'h_trace', h_trace, 'ax', ax_snippet,'contour_thresh',0.05);
        hold(ax_snippet, 'off');

    end
    
    function [x_current, y_current] = get_active_region(idx_current_cell)
        % Get images
        images = full(cellcheck.ims(:, :, idx_current_cell));
        idx_neighbor = cellcheck.neighbors{idx_current_cell};
        if ~isempty(idx_neighbor)
            ims_neighbor = full(cellcheck.ims(:, :, idx_neighbor));
            images = max(cat(3, images, ims_neighbor), [], 3);
        end
        % get the extent of the roi
        [x_range, y_range] = get_image_xy_ranges(images> 0.2, 1);
        x_current = x_range(1):x_range(2);
        y_current = y_range(1):y_range(2);
    end

    function neighbors = get_all_neighbors(cellcheck)
        n_components = size(cellcheck.ims, 3);
        neighbors = cell(1, n_components);
        [h, w, k] = size(cellcheck.ims);
        ims_f=cellcheck.ims;
        
        
        for i=1:k
            im_n=full(ims_f(:,:,i));
            im_n = im_n / sum(im_n(:));  % make it sum to one
            x_center(i) = sum((1:w) .* sum(im_n, 1));
            y_center(i) = sum((1:h)' .* sum(im_n, 2));
            
        end
        avg_radius=output.config.avg_cell_radius;
        C=zeros(k,k);
        for i=1:k
            tempx= (abs(x_center(i)-x_center)<2*avg_radius);
            tempy= (abs(y_center(i)-y_center)<2*avg_radius);
            C(i,:)=tempx.*tempy;
        end
        
        %ims_flat = reshape(cellcheck.ims, h*w, k);
        % If ndSparse, convert to sparse
        %if isa(ims_flat, 'ndSparse')
        %    ims_flat = sparse(ims_flat);
        %end
        %ims_flat = zscore(ims_flat, 1, 1) / sqrt(size(ims_flat, 1));
        %C = ((ims_flat' * ims_flat) > 0);
        for i = 1:n_components
            neighbors{i} = setdiff(find(C(i, :)), i);
        end
    end

%     function ims_small = get_roi_small(ims)
%         ims_small = cell(size(ims, 3));
%         for i = 1:size(ims, 3)
%             im = ims(:, :, i);
%             [x_range, y_range] = get_image_xy_ranges(im, 5);
%             ims_small{i} = im(y_range(1):y_range(2), x_range(1):x_range(2));
%         end
%         % Don't output a cell if only 1 image
%         if size(ims, 3) == 1
%             ims_small = ims_small{1};
%         end
%     end
% 
%     function plot_roi_small
%         im = cellcheck.ims(:, :, idx_current_cell);
%         [x_range, y_range] = get_image_xy_ranges(im, 0);
%         imagesc(ax_cell_image, im(y_range(1):y_range(2), x_range(1):x_range(2))); 
%         axis(ax_cell_image, 'equal', 'off');
%         colormap(ax_cell_image, flipud(brewermap(64, 'rdbu')));
%     end

    function x = convert_to_int(x)
        % Shift & scale to be in the range [0, 256]
        x = x - min(x(:));
        x = x / max(x(:)) * 256;
        x = uint8(x);
    end

    function colors = label_to_color_mapping(labels)
        colors = cell(1, length(labels));
        l1 = labels == 1;
        l0 = (labels == 0) | (labels == -2);
        lm1 = labels == -1;
        colors(l1) = {color_good};
        colors(l0) = {color_unlabeled};
        colors(lm1) = {min(1, color_bad + ones(1, 3)*0.5)};
        % Don't output cell array if length is 1
        if length(colors) == 1
            colors = colors{1};
        end

    end

    function add_callback(h, callback_field, callback_fcn)
        % Add callback, and make uninterruptible (objects get deleted
        % otherwise and errors happen when continuing interrupted callback)
        set(h, callback_field, callback_fcn, 'Interruptible', false);
    end

    function h = make_axes(parent, x_start, y_start, x_len, y_len, margin)
        h = axes(parent, 'Position', [x_start+margin, y_start+margin, x_len-2*margin, y_len-2*margin]);
    end

    function clims = get_clims(im)
        clims = [quantile(im(:), 0.1), quantile(im(:), 0.999)];
    end

    function clear_axes(ax)
        c = get(ax, 'children');
        for i = 1:length(c)
            delete(c(i));
        end
    end

    function clear_accessories_in_axes(ax)
        c = get(ax, 'children');
        for i = 1:length(c)
            obect_type = get(c(i), 'type');
            if ismember(obect_type, {'text', 'line' 'patch'})
                delete(c(i));
            end
        end
    end

    function show_content(ax)
        c = get(ax, 'children');
        for i = 1:length(c)
            c(i).Visible = 'on';
        end
    end

    function hide_content(ax)
        c = get(ax, 'children');
        for i = 1:length(c)
            c(i).Visible = 'off';
        end
    end

    function pos = subpos(pos_norm, parent_pos_pix)
        pos = pos_norm;
        pos(2) = pos(2)* parent_pos_pix(4);
        pos(4) = pos(4)* parent_pos_pix(4);
        pos(1) = pos(1)* parent_pos_pix(3);
        pos(3) = pos(3)* parent_pos_pix(3);
    end

    function pos_pix = norm2pix(pos_norm, parent_pos_pix)
        pos_pix = zeros(1, 4);
        pos_pix(1) = parent_pos_pix(1) + parent_pos_pix(3)*pos_norm(1);
        pos_pix(2) = parent_pos_pix(2) + parent_pos_pix(4)*pos_norm(2);
        pos_pix(3) = parent_pos_pix(3)*pos_norm(3);
        pos_pix(4) = parent_pos_pix(4)*pos_norm(4);
    end

    function idx_selected_events = select_events(idx_events, n_events)
        % Select n_events nearly equidistant events from a larger array 
        % idx_events
        ideal = linspace(min(idx_events), max(idx_events), n_events);
        % Get matches
        idx_selected_events = zeros(1, n_events);
        for i = 1:n_events
            [~, idx] = min((ideal(i) - idx_events).^2);
            idx_selected_events(i) = idx_events(idx);
            idx_events(idx) = inf;
        end 
    end

    function update_labels
        num_cells = length(extract_labels);
        for i = 1:num_cells
            labels(i) = extract_labels(i);
            % User overrides
            user_label = user_labels(i);
            if user_label ~= 0
                labels(i) = user_label;
            end
        end
    end

    function update_extract_labels
        is_p = extract_scores > score_upper_threshold;
        is_n = extract_scores < score_lower_threshold;
        temp_labels = zeros(size(extract_labels));
        temp_labels(is_p) = 1;
        temp_labels(is_n) = -1;
        % Don't mess with already eliminated cells as far as auto-labeling
        % is concerned
        extract_labels(~is_elim) = temp_labels(~is_elim);
    end

    function M_out = get_movie(t_range)    
        if ischar(M) || iscell(M)
            [path, dataset] = parse_movie_name(M);
            x_begin = x_current(1);
            x_end = x_current(end);
            y_begin = y_current(1);
            y_end = y_current(end);
            t_begin = t_range(1);
            t_end = t_range(end);
            idx_begin = [y_begin, x_begin, t_begin];
            num_elements = [y_end - y_begin + 1, x_end - x_begin + 1, ...
                t_end - t_begin + 1];
            M_out = h5read(path, dataset, idx_begin, num_elements);
        else
            M_out = M(y_current, x_current, t_range);
        end
        % Make sure output is single
        M_out = single(M_out);
        % Replace nan pixels with zeros
        M_out = replace_nans_with_zeros(M_out);
        % Remove zero edges
        [M_out, nz_top, nz_bottom, nz_left, nz_right] = ...
        remove_zero_edge_pixels(M_out);
        y_current = y_current(nz_top+1:end-nz_bottom);
        x_current = x_current(nz_left+1:end-nz_right);
        % Preprocess
        if output.config.preprocess
            % Get new config
            this_config = output.config;
            % Make movie mask size consistent if it exists
            if ~isempty(this_config.movie_mask)
                this_config.movie_mask = ...
                    this_config.movie_mask(y_current, x_current);
            end
            % Do manual dff (using config)
            if isfield(output.info, 'F_per_pixel')
                F_per_pixel = output.info.F_per_pixel(y_current, x_current);
                M_out = bsxfun(@minus, M_out, F_per_pixel);
                M_out = bsxfun(@rdivide, M_out, F_per_pixel);
            end
            % Turn off dff
            this_config.skip_dff = true;
            M_out = preprocess_movie(M_out, this_config);
           
        end
    end

    function [output, output_handle] = parse_output(output)
        % Easy if output is string: extract data and point to its handle
        if ischar(output)
            output_handle = matfile(output, 'Writable', true);
            output = output_handle.output;
        % We need to create a new file for output
        else
            file_suffix = '_EXTRACT_output';
            if ischar(M)
                % Make name same as the movie string name
                [path, ~] = parse_movie_name(M);
                [dir, name, ~] = fileparts(path);
                path = name;
                if ~isempty(dir)
                    path = [dir, '/', path];
                end
            else
                % Create a new file in the current directory
                path = '';
            end
            
            output_handle = matfile([path, file_suffix], 'Writable', true);
        end
    end
end
