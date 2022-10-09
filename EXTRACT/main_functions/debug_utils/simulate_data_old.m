function[M,F_mat,T_mat,event_times, cents] = simulate_data(...
    movie_size,num_cells,minmax_cell_radius,min_cell_spacing,...
    event_rate,event_tau,event_SNR,noise_std,add_neuropil)
% Simulate data for given params

    refractory_period = 4;
    
    % Set random seed (optional) for reproducable results
    if ~exist('add_neuropil','var')
        add_neuropil=0;
    end
    
    h = movie_size(1);
    w = movie_size(2);
    t = movie_size(3);
    
    M = zeros(h*w,t);
    F_mat = zeros(h*w,num_cells);
    T_mat = zeros(num_cells,t);
    event_times = {};
    
    min_radius = minmax_cell_radius(1);
    max_radius = minmax_cell_radius(2);
    
    % Temp_kernel is convolved later with binary spike train
    temp_kernel = exp(-(1:5*event_tau)/event_tau);
    temp_kernel = event_SNR*noise_std*temp_kernel/max(temp_kernel);  
    
    % Buffer space is added to FOV for creating cells on the edges
    buffer = ceil(max_radius);
    half_width = ceil(max_radius);
    
    cents = [];    
    acc=0;
    while true
        
        cent = ceil([rand*h,rand*w]);
        
        % Discard if this cell is too close to any other or boundary
        if ~isempty(cents)
            dists = bsxfun(@minus,cents,cent);        
            if any(sqrt(sum(dists.^2,2))<min_cell_spacing) ||...
                (cent(1)< max_radius/2) || (cent(1) > h-max_radius/2) ||...
                (cent(2)< max_radius/2) || (cent(2) > w-max_radius/2)
                continue;
            end
        end
        acc = acc+1;
        
        %-------------------
        % Compute cell image
        %-------------------
        
        % Sample 2 variables(for x and y) between min and max radii
        radii = min_radius+rand(1,2)*(max_radius-min_radius);
        % Std matrix for gaussian shaped cell with no skewness
        sigmasq = (diag(radii)/2).^2;
        % Add random skewness
        [Q,~] = qr(randn(2));
        sigmasq = Q*sigmasq*Q';
        % Generate image
        [x,y] = meshgrid(1:2*half_width+1,1:2*half_width+1);
        mu = max_radius+1;
        f = mvnpdf([x(:),y(:)],mu,sigmasq);
        f = reshape(f,2*half_width+1,2*half_width+1);
        % Place image in FOV
        F = zeros(h+buffer*2,w+buffer*2);
        F((cent(1)-half_width + buffer):(cent(1)+half_width + buffer),...
            (cent(2)-half_width + buffer):(cent(2)+half_width + buffer)) = f;
        F = F(buffer+1:end-buffer,buffer+1:end-buffer);
        F = reshape(F,h*w,1);
        F = F/max(F);
        F(F<0.05) = 0;
        
        %-------------------
        % Compute cell trace
        %-------------------
        spikes = false(1, t);
%         event_rate_this = event_rate + randn*event_rate/4;
        i = 1;
        while i <= t
            is_spike = rand <=event_rate;
            if is_spike
                spikes(i) = true;
                i = min(t, i+refractory_period);
            else
                i = i+1;
            end
        end
        T = conv(spikes,temp_kernel);
        T = T(1:t);
        
        
        %----------------
        % Update matrices
        %----------------
        
        F_mat(:,acc) = F;
        T_mat(acc,:) = T;
        event_times{acc} = find(spikes);
        cents = [cents;cent];
        
        % Termination
        if acc == num_cells
            break;
        end
        
    end
    
    %------------------
    % Add noise, make M
    %------------------
    if add_neuropil
        M_neuropil = load('M_background');
        M_neuropil = double(M_neuropil.M_background);
        M_neuropil = M_neuropil(1:h,1:w,1:t);
        M_neuropil = reshape(M_neuropil,h*w,t);
        std_neuropil = std(M_neuropil(:));
        noise = make_some_noise(noise_std/sqrt(2));
        noise = noise+M_neuropil/std_neuropil*noise_std/sqrt(2);
    else
        noise = make_some_noise(noise_std*sqrt(3/3));
        correlated_noise = make_correlated_noise(noise_std*sqrt(0/3), 5*mean(minmax_cell_radius), event_tau);
        noise = noise+correlated_noise;
    end
    
    M = F_mat*T_mat + noise;
    M = reshape(M,h,w,t);
    
    function noise = make_some_noise(noise_std)
        noise = randn(h*w,t)*noise_std;
    end

    function noise = make_correlated_noise(noise_std, radius, tau)
        noise = randn(h,w,t);
        noise = spatial_bandpass(noise, radius, 2,2, 1);
        noise = reshape(noise, h*w, t);
        noise = conv2(1, exp(-(1:(tau*5))/tau), noise, 'same');
        noise = noise/std(noise(:)) * noise_std;
    end
  fprintf('simulated data pre\n');  
end

