function M = load_h5(source, dataset_str)
% Light wrapper around h5read with default dataset str

if ~exist('dataset_str', 'var')
    dataset_str = '/Data/Images'; % '/1'
end
M = h5read(source, dataset_str);
end
