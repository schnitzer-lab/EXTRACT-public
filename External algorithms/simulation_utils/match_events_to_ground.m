function [rate_truepos, rate_falsepos] = match_events_to_ground(ground_collection, est_collection)
% Match estimated events to ground truth events
    dist_thresh = 3;
    num_cells=length(ground_collection);
    rate_truepos=zeros(1,num_cells);
    rate_falsepos=zeros(1,num_cells);

    for idx_cell=1:num_cells
        times_ground=single(ground_collection{idx_cell});
        times_est=single(est_collection{idx_cell});
        if isempty(times_est)
            continue;
        end
        if ~isempty(times_ground)
            num_est = length(times_est);
            num_ground = length(times_ground);
            if size(times_ground,1)>1
                times_ground=times_ground';
            end
            if size(times_est,1)>1
                times_est=times_est';
            end
            mag_ground = repmat((times_ground').^2, 1, num_est);
            mag_est = repmat((times_est).^2, num_ground, 1);
            dists = mag_ground+mag_est - 2* times_ground'*times_est;
            num_truepos = 0;
            while true
                [m,i] = min(dists(:));
                if m>dist_thresh^2
                    break
                end
                [i1,i2] = ind2sub([num_ground, num_est],i);
                num_truepos=num_truepos+1;
                dists(i1,:) = inf;
                dists(:,i2) = inf;

            end
            rate_truepos(idx_cell)=num_truepos/num_ground;
            if num_est > 0
                rate_falsepos(idx_cell)=(num_est-num_truepos)/num_est;
            end
        else
            rate_truepos(idx_cell)=1;
        end
    end

    rate_falsepos(rate_falsepos<0)=0;

end