function plot_stacked_traces_double(T,T2, is_numbered, color, plot_spacing,...
    textsize, trace_linewidth)
    
    if nargin< 7 || isempty(trace_linewidth)
        trace_linewidth = {1.5,1.5};
    end
    if nargin< 6 || isempty(textsize)
        textsize = 15;
    end
    if nargin< 5 || isempty(plot_spacing)
        plot_spacing = quantile(T(:), 0.999);
    end
    if nargin < 4 || isempty(color)
        color = {'black',[0.2,1,0.3]};
    end
    xlen = 0.5;
    ylen = 0.5;
    hf = figure('units','normalized','position',[0.5-xlen/2 0.5-ylen/2 xlen ylen]);
    set(hf,'renderer','painters')

    num_traces = size(T, 1);
    
    plot_offset = plot_spacing * (num_traces-1:-1:0)';
    T = bsxfun(@plus, T, plot_offset);
    if ~isempty(T2)
        T2 = bsxfun(@plus, T2, plot_offset);
    end
    %set(gca,'ColorOrder', map, 'NextPlot', 'ReplaceChildren');
    plot(T', 'linewidth', trace_linewidth{1},'color',color{1});
    hold on
    if ~isempty(T2)
        plot(T2', 'linewidth', trace_linewidth{2},'color',color{2});
        hold on
    end
    if nargin >=2 && is_numbered
        % Put numbers next to cells
        for i = 1:length(plot_offset)
            text(0, double(plot_offset(i)), num2str(i),...
                'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'FontSize', textsize)
        end
    end
    ylim([min(T(:)), max(T(:))]);
    axis off;
end