function verify_initialization(M,Im_init,T_init,idx)

t_init = T_init(idx,:);
[~,~,t] = size(M);

% Extract boundaries
bs = {};
for i=1:size(Im_init,3)
    b = bwboundaries(Im_init(:,:,i)>0.2);
    b = b{1};
    bs{end+1}=b;
end

movie_clim = compute_movie_scale(M);
subplot(4,4,1:12);
hi = imagesc(M(:,:,1), movie_clim);
hold on
for i = 1:size(Im_init,3)
    if i==idx,c = 'g';else c = [0.5,0.6,1]; end
    plot(bs{i}(:,2),bs{i}(:,1), 'Color', c, 'LineWidth',2);
%     end
end
hold off
axis image
colormap bone
subplot(4,4,13:16)
plot(t_init,'LineWidth',2);
hold on
hpp = plot(1,t_init(1),'o','LineWidth',5);
hold off

for k = 1:t
    title(sprintf('Frame %d of %d', k, t));
    set(hi, 'CData', M(:,:,k));
    set(hpp,'XData',k);
    set(hpp,'YData',t_init(k));
    drawnow;
end

    function clim = compute_movie_scale(M)
        % Compute an appropriate viewing scale (CLim) for the provided movie

        [height, width, ~] = size(M);
        maxVec = reshape(max(M,[],3), height*width, 1);
        minVec = reshape(min(M,[],3), height*width, 1);
        quantsMax = quantile(maxVec,[0.85,0.87,0.9,0.93,0.95]);
        quantsMin = quantile(minVec,[0.85,0.87,0.9,0.93,0.95]);

        clim = [mean(quantsMin) mean(quantsMax)];
        clim_range = clim(2)-clim(1);
        clim = clim + 0.1*clim_range*[-1 1];
    end
end