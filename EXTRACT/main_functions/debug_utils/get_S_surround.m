function S_surround = get_S_surround(S, fov_size, rel_width)

    if nargin < 3 || isempty(rel_width)
        rel_width = 1;
    end
    h = fov_size(1);
    w = fov_size(2);
    radius = estimate_avg_radius(S, [h, w]);
    mask = make_mask(S>0.1, [h, w], radius*rel_width);
    S_surround =  ones(size(S), class(S));
    % Exclude cell
    S_surround(S > 0.1) = 0;
    % Exclude masked-out region
    S_surround(~mask) = 0;
    % Normalize to 1
    S_surround = normalize_to_one(S_surround);
end