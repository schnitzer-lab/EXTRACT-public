function out_array = get_bad_cell_stats(output, idx_partition)

    attrs = {'is_T_duplicate', 'is_S_duplicate', 'is_T_zeroed',...
        'is_T_poor_looking', 'is_S_tiny', 'is_S_huge' , ...
        'is_S_poor_looking' , 'is_S_poor_eccent', 'is_ST_spurious'};
    
    classifications = output.info.summary(idx_partition).classification;
    num_iters = length(classifications);
    out_array = zeros(length(attrs), length(classifications)+1);
    for j = 1:num_iters
        out_array(:, j+1) = sum(classifications(j).is_attr_bad, 2);
    end
    out_array = diff(out_array, 1, 2);
    
    format_str = '%s : ';
    for i = 1:num_iters
        format_str = strcat(format_str, ' %d');
    end
    format_str = strcat(format_str, '\n');
    for idx_attr = 1:length(attrs)
        fprintf(format_str, attrs{idx_attr}, out_array(idx_attr, :)');
    end
    
    