function [path, dataset] = parse_movie_name(M)
    str_cell = strsplit(M, ':');
    if length(str_cell) ~= 2
        error('Movie string must be in the format "filepath:dataset"');
    end
    [path, dataset] = deal(str_cell{:});
end