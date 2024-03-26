function plot_output_cellmap(output, include_bad_cells, varargin)

plot_init_locations = false;
clim_scale = [0, 0.95];
for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case 'plot_init_locations'
                plot_init_locations = varargin{k+1};
            case 'clim_scale'
                clim_scale = varargin{k+1};
        end
    end
end

if nargin < 3 || isempty(plot_init_locations)
    plot_init_locations = false;
end

if nargin < 2 || isempty(include_bad_cells)
    include_bad_cells = 10;
end

max_im = output.info.summary_image;
clims = quantile(max_im(:), clim_scale);
imagesc(max_im, clims);
axis image; axis off;
colormap(flipud(brewermap(64, 'rdgy')));
[h, w] = size(max_im);

title_str = '';
num_partitions = length(output.info.summary);
if include_bad_cells > 0
    num_bad_cells = 0;
    for i_part = 1:num_partitions
        %fprintf('Plotting bad cells for partition %d (of %d)...\n', i_part, num_partitions);
        classification = output.info.summary(i_part).classification;
        if isempty(classification)
            continue;
        end
        is_attr_bad = classification(end).is_attr_bad;
        % Exclude good cell indices from is_attr_bad
        num_good_cells = size(output.info.summary(i_part).S_change, 1);
        is_attr_bad(:, 1:num_good_cells) = [];
        S_bad_small = output.info.summary(i_part).S_bad;
        if include_bad_cells == 10
            idx_bad = 1:size(S_bad_small, 2);
        else
            idx_bad = find(is_attr_bad(include_bad_cells, :));
        end
        S_bad = zeros(h*w, size(S_bad_small, 2));
        S_bad(output.info.summary(i_part).fov_occupation(:), :) = S_bad_small;
        ims_bad = reshape(S_bad, h, w, size(S_bad, 2));
        plot_cells_overlay(ims_bad(:, :, idx_bad), 'r', []);
        num_bad_cells = num_bad_cells + length(idx_bad);
    end
    %fprintf('Plotting good cells...\n');
    plot_cells_overlay(output.spatial_weights, 'g', []);
    title_str = sprintf(' \n# eliminated cells: %d', num_bad_cells);
else
    plot_cells_overlay(output.spatial_weights, [0, 0.7, 0.1], 1.5);
end
title_str = [sprintf('# output cells: %d    ', size(output.spatial_weights, 3)),...
    title_str];
title(title_str, 'fontsize', 14);

% Plot init locations
if plot_init_locations
    init_color = [1, 0.5, 0];
    cell_offset = 0;
    for i_part = 1:num_partitions
        init_locations = output.info.summary(i_part).init_summary.max_locations;
        fov_occupation = output.info.summary(i_part).fov_occupation(:);
        num_cells_this_partition = size(init_locations, 2);
        i_offset = find(fov_occupation>0, 1);
        [y_offset, x_offset] = ind2sub([h, w], i_offset);
        hold on;
        scatter(init_locations(2, :)+y_offset-1, init_locations(1, :)+x_offset-1,...
            30, init_color, 'x');
        hold off;
        texts = cellfun(@num2str,...
            num2cell((cell_offset + 1):(cell_offset + num_cells_this_partition)), ...
            'uniformoutput', false);
        text(init_locations(2, :)+y_offset+1,...
            init_locations(1, :)+x_offset, texts, 'color', init_color,...
            'fontsize', 6);
        cell_offset = cell_offset + num_cells_this_partition;
    end
end