function [path, dataset] = parse_movie_name(M)
    str_cell = strsplit(M, ':');
    if length(str_cell) == 2
        [path, dataset] = deal(str_cell{:});
    elseif length(str_cell) > 2
        s = length(str_cell);
        path = [];
        for i = 1:s-1
            path = [path str_cell{i} ':'];
        end
        path = path(1:end-1);
    
        dataset = str_cell{end};
    else
        error('Movie string must be in the format "filepath:dataset"');
    end
end