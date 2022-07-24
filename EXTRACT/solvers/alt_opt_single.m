function [s, t, t_corr, s_corr, s_change, t_change] = ...
        alt_opt_single(Mt ,f_2d_init, noise_std, size_limit, use_gpu, kappa_t, kappa_s,max_iter)

if nargin <8
    max_iter = 10;
end

[h, w] = size(f_2d_init);

s_blank = maybe_gpu(use_gpu, zeros(h * w, 1, 'single'));

n_iter_in = max_iter;
n_iter_out =max_iter;
TOL = 1e-1;
scale_lambda = 0;
extend_radius_low = 3;
extend_radius_high = 6;
se_low = strel('disk', extend_radius_low);
se_high = strel('disk', extend_radius_high);

s = reshape(f_2d_init, h * w, 1);
t = 1e6;
s_2d = reshape(s, h, w);

s_change = zeros(1, n_iter_out, 'single');
t_change = zeros(1, n_iter_out, 'single');
is_s = [];
M_sub = [];
for i = 1:n_iter_out
    s_before = s;
    t_before = t;
    % Get a movie chunk
    [is_s, M_sub] = get_M_sub(Mt, M_sub, s_2d, is_s, use_gpu, ...
        extend_radius_low, extend_radius_high);
    % T update
    s_sub = s(is_s);
    lambda = sum(s_sub) * scale_lambda;
    t = solve_single_source_adaptive(s_sub, M_sub, n_iter_in, lambda, noise_std, kappa_t);
    
% %     Median-filter t
%     t = maybe_gpu(use_gpu, medfilt1(gather(t)));
    
    if sum(t)==0
        break;
    end
    % S update (transpose when necessary)
    t_noise_limit = sqrt(2)*3*estimate_noise_std(t);
    idx_valid_t = find(t>t_noise_limit);
    M_subsub =  M_sub(:, idx_valid_t);
    t_sub = t(idx_valid_t)';
    lambda = sum(t_sub) * scale_lambda;
    s_sub = solve_single_source_adaptive(t_sub, M_subsub', n_iter_in, lambda, noise_std, kappa_s)';
%     if exist('kappa_func', 'var')
%         s_sub = solve_single_source_adaptive(t_sub, M_subsub', n_iter_in, lambda, kappa, kappa_func)';
%     else
%         s_sub = solve_single_source_adaptive(t_sub, M_subsub', n_iter_in, lambda, kappa)';
%     end

    s = s_blank;
    s(is_s) = s_sub;
    s = s / max(max(s), 1e-10);
    
    s_2d = reshape(s, h, w);
    if (sum(s)==0) || (sum(t)==0) || (sum(is_s)>size_limit)
        break;
    end

    % Termination condition
    s_change(i) = gather(sum(abs(s - s_before)) / sum(s+s_before)*2);
    t_change(i) = gather(sum(abs(t - t_before)) / sum(t+t_before)*2);
    
    if  s_change(i)< TOL && t_change(i) < TOL
        break;
    end
end

% Correlation image
if ~exist('M_subsub', 'var') % Break invoked before first s update
    s_corr = s_blank;
elseif (size(M_subsub,2)==1)
    s_corr = s_blank;
else
    s_sub = M_subsub * (t_sub / (t_sub'*t_sub)) ;
    s_corr = s_blank;
    s_corr(is_s) = max(0, s_sub);
end

% Correlation trace
is_pos_s = s>0;
M_sub = ( maybe_gpu(use_gpu, Mt(:, is_pos_s(:))) )';
sn = s / sum(s.^2);
t_corr = max(0, sn(is_pos_s)' * M_sub);

    function [is_s, M_sub] = get_M_sub(Mt, M_sub, s_2d, is_s, use_gpu, ...
            extend_radius_low, extend_radius_high)
        % CPU is better with imdilate, gpu is better with imfilter
        if use_gpu
            is_s_minimal = get_support_gpu(s_2d, extend_radius_low);
        else
            is_s_minimal = get_support_cpu(s_2d, se_low);
        end
        if isempty(is_s) || any(~is_s(is_s_minimal))
            if use_gpu
                is_s = get_support_gpu(s_2d, extend_radius_high);
            else
                is_s = get_support_cpu(s_2d, se_high);
            end
            
            M_sub = ( maybe_gpu(use_gpu, Mt(:, is_s)) )';
        end
    end
    
    function is_in_support = get_support_cpu(s_2d, se)
        is_in_support = imdilate(s_2d>0.1 * max(s_2d(:)), se);
        is_in_support = is_in_support(:);
    end

    function is_in_support = get_support_gpu(s_2d, extend_radius)
        filt = double(fspecial('disk', extend_radius) > 0);
        is_in_support = imfilter(s_2d > 0.1 * max(s_2d(:)), filt, 'replicate');
        is_in_support = is_in_support(:)>0;
    end
end
