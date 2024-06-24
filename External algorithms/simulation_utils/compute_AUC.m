function [aucs] = compute_AUC(rocs)


    if isempty(rocs)
        aucs = NaN;
        return
    end
    
    num_cells = size(rocs, 3);
    
    for j = 1:num_cells  % Each cell
        % Sort wrt fpr
        [~,idx] = sort(rocs(2,:, j));
        rocs(:,:, j) = rocs(:,idx, j);

        % Sort tpr when fpr is constant
        [~,~,memberships] = unique(rocs(2,:, j));
        for k = 1:memberships(end)
            idx = find(memberships==k);
            if length(idx)>1
                rocs(1,idx, j) = sort(rocs(1,idx, j));
                % Replace constant fprs with slightly increasing values
                rocs(2,idx, j) = rocs(2,idx, j)+1e-4*(1:length(idx));
            end
        end

        
    % Safeguard against glitches causing decreasing tpr
        for rp = 1:100 % repeat n times, fixes n consecutive declines
            d = find(diff(rocs(1,:,j), 1, 2)<0);
            for k=1:length(d)
                d_this = d(k);
                rocs(1,d_this+1, j) = rocs(1,d_this, j);
            end   
        end
    end
    % extrapolate curves to fpr of 1
    last_slice = rocs(:, end, :);
    last_slice(2, :, :) = 1;
    rocs = cat(2, rocs,last_slice); 
    % Compute AUC
    aucs = 0;
    for j = 1:num_cells
        aucs = aucs + trapz(rocs(2,:, j),rocs(1,:, j))/num_cells;
    end


end

