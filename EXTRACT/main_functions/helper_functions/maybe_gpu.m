function varargout = maybe_gpu(use_gpu, varargin)
% Transfer inputs to gpu if use_gpu is true
    varargout = varargin;
    if use_gpu
        for i = 1:length(varargout)
            varargout{i} = gpuArray(varargout{i});
        end
    end
end