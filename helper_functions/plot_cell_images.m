function h = plot_cell_images(ax, ims, face_color, edge_color, varargin)
    
    callback_fn = [];
    str_code = [];
    edge_alpha = 1;
    face_alpha = 0.1;
    linewidth = 1;
    smooth_func = @(x) x;
    linestyle = '-';
    display_thr = 0.3;
    for k = 1:length(varargin)
        vararg = varargin{k};
        if ischar(vararg)
            switch lower(vararg)
                case 'callback_fn'
                    callback_fn = varargin{k+1};
                case 'str_code'
                    str_code = varargin{k+1};
                case 'display_thr'
                    display_thr = varargin{k+1};
                case 'linewidth'
                    linewidth = varargin{k+1};
                case 'smooth_func'
                    smooth_func = varargin{k+1};
                case 'linestyle'
                    linestyle = varargin{k+1};
                case 'edge_alpha'
                    edge_alpha = varargin{k+1};
                case 'face_alpha'
                    face_alpha = varargin{k+1};
            end
        end
    end

    
    h = cell(1, size(ims, 3));
    for idx = 1:size(ims, 3)
        b = get_im_boundary(full(ims(:,:,idx)), display_thr);
        if ~isempty(b)
            if iscell(face_color)
                c = face_color{idx};
            else
                c = face_color;
            end
            if iscell(edge_color)
                ec = edge_color{idx};
            else
                ec = edge_color;
            end
            
            h_this = fill(ax, smooth_func(b(:,2)), smooth_func(b(:,1)),c, ...
                'EdgeColor', ec, 'LineWidth', linewidth,...
                'FaceAlpha', face_alpha,'EdgeAlpha', edge_alpha, ...
                'FaceColor', c,'LineStyle', linestyle);
            
            if ~isempty(callback_fn)
                set(h_this, 'ButtonDownFcn', callback_fn);
            end
            if ~isempty(str_code)
                h_this.DisplayName = [str_code, num2str(idx)];
            else
                h_this.DisplayName = num2str(idx);
            end
            h{idx} = h_this;
        end
    end

end