devs = [];
se = strel('disk',3);
mask = filters>0;
proj_mask_x = sum(mask,1)>0;
proj_mask_y = sum(mask,2)>0;
for i = 1:size(filters,3)
    y_range = find(squeeze(proj_mask_y(:,:,i)));
    x_range = find(squeeze(proj_mask_x(:,:,i)));
    f = filters(:,:,i);
    mf = medfilt2(f);
    idx_valid = bwconvhull(mf>0);
    idx_valid = idx_valid(:);
    f = f(idx_valid);
    mf = mf(idx_valid);
    
    dev_im = (f-mf);
    %z = max(max(abs(f),abs(mf)),1e-12);
    %dev_im = dev_im./z;

    dev = mean(abs(dev_im));%norm(dev_im(:))/sqrt(sum(cv(:)));
    subplot(121)
    imagesc(filters(y_range,x_range,i));
    axis image;
    subplot(122)
    im2 = imerode(filters(:,:,i),se);
    imagesc(im2(y_range,x_range));
    axis image;
    title(num2str(dev));
    pause;   
    devs(end+1)=dev;
end