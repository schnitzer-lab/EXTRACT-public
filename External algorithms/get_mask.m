function mask = get_mask(M)


    [nx, ny, ~] = size(M);

    figure

    imshow(mean(M,3),[])
    

    rect = getrect
    y_min = round(rect(1))
    x_min = round(rect(2))
    y_max = round(rect(1)+rect(3))
    x_max = round(rect(2)+rect(4))
    mask = zeros(nx,ny);
    mask(x_min:x_max,y_min:y_max) = 1;

end
   
