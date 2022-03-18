function areas = get_cell_areas(S, threshold)

if nargin < 2 || isempty(threshold)
    threshold = 0.1;
end

areas = sum(S > threshold, 1);

end