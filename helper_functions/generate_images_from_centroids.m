function F = generate_images_from_centroids(h,w,f,cents,radius)

k = size(cents,2);
F = zeros(h*w,k,'single');
half_buffer = radius*2;
for i = 1:k
    cent = cents(:,i);
    F_single = zeros(h+half_buffer*2,w+half_buffer*2,'single');
    y_range = (cent(1)-radius + half_buffer):...
        (cent(1)+radius + half_buffer);
    x_range = (cent(2)-radius + half_buffer):...
        (cent(2)+radius + half_buffer);
    F_single(y_range, x_range) = f;
    F_single = F_single(half_buffer+1:end-half_buffer,half_buffer+1:end-half_buffer);
    F_single = reshape(F_single,h*w,1);
    F(:,i) = F_single;
end