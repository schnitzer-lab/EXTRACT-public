function[M,F_mat,T_mat,event_times,spike_amps, cents] = simulate_data(...
    movie_size,num_cells,minmax_cell_radius,min_cell_spacing,...
    event_rate,event_tau,event_SNR,noise_std,ratio_corr_noise, ...
    exponential_traces,spike_range,spike_sync_prob, refractory_period,synch_prob_interval,donut_filter)
    
    if nargin< 9
        ratio_corr_noise = 0;
    end
   
    if nargin< 10
        exponential_traces = 1;
    end

    if nargin< 11
        spike_range = 1;
    end

    if nargin< 12
        spike_sync_prob = 0;
    end

    if nargin< 13
        refractory_period = 3;
    end

    if nargin < 14
        synch_prob_interval = [200,600];
    end

    if nargin<15
        donut_filter = 0;
    end


    % Update the even rate and sync rates!
    if spike_sync_prob > 0
        event_rate_full = event_rate;
        event_rate = event_rate_full * (1-spike_sync_prob);
        spike_sync_rate = event_rate_full * spike_sync_prob;
    end
    
    h = movie_size(1);
    w = movie_size(2);
    t = movie_size(3);

    F_mat = zeros(h*w,num_cells);
    T_mat = zeros(num_cells,t);
    event_times = cell(1, num_cells);
    spike_amps = cell(1, num_cells);
    
    min_radius = minmax_cell_radius(1);
    max_radius = minmax_cell_radius(2);
    
    % Temp_kernel is convolved later with binary spike train
    if exponential_traces
        temp_kernel = exp(-(1:5*event_tau)/event_tau);
        kernel_offset = 1;
    else
        temp_kernel = tripuls((1:5*event_tau)-2.5*event_tau, event_tau*2.5, -0.8);
        [~, kernel_offset] = max(temp_kernel);
    end
    temp_kernel = event_SNR*noise_std*temp_kernel/max(temp_kernel); 
        
    
    % Buffer space is added to FOV for creating cells on the edges
    buffer = ceil(max_radius);
    half_width = ceil(max_radius);
    
    %%%%%%%%%%%%%%%
    % Generate spikes
    %%%%%%%%%%%%%%%
    
    spikes = false(num_cells, t);
    spiked_recently = false(num_cells, 1);
    for k = 1:t
        % Sample bernoullis
        is_spike = rand(num_cells, 1) <=event_rate ;
        % Enforce refractory period
        is_spike(spiked_recently) = 0;
        spikes(:, k) = is_spike;
        % Update spike history
        spiked_recently = any(spikes(:, max(1, k-refractory_period):k), 2);
    end
%     % shift spikes within groups
%     for i = 1:nc
%         idx = (i-1)*ng + (1:ng);
%         spikes(idx, :) = circshift(spikes(idx, :), 3*i, 2);
%     end


    % Assign all neurons to synced groups
    if spike_sync_prob > 0
        for k = 1:t
            nc = randi(synch_prob_interval);
            spike_sync_prob_temp = spike_sync_rate * num_cells / nc;
            if k == 1
                spiked_recently = false(num_cells, 1);
            else
                spiked_recently = any(spikes(:, max(1, k-refractory_period-1):k-1), 2);    
            end
            if rand <= spike_sync_prob_temp
                % Pick neurons to spike together
                ind_neurons = randi([1,num_cells],[1,nc]);
                spikes(ind_neurons,k) = 1;
            end
            
            % Enforce refractory period
            spikes(spiked_recently, k) = 0;
        end
    end
    

    for idx_cell = 1:num_cells
        event_times{idx_cell} = find(spikes(idx_cell, :));
    end



    cents = zeros(num_cells, 2);    
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
        if donut_filter == 0
            [x,y] = meshgrid(1:2*half_width+1,1:2*half_width+1);
            mu = max_radius+1;
            f = mvnpdf([x(:),y(:)],mu,sigmasq);
            f = reshape(f,2*half_width+1,2*half_width+1);
        else
            [x,y] = meshgrid(-half_width:half_width,-half_width:half_width);
            mu = max_radius+1;
            f  =  exp( - (sqrt(x.^2 + y.^2) - 0.5*mu ).^2 ./ (0.1 .* mu.^2 )  );
            f = reshape(f,2*half_width+1,2*half_width+1);
        end
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
        if (spike_range == 0)
            T = conv(spikes(acc, :),temp_kernel);
        else
            %random_spk_gen = randi([1 spike_range],1,size(spikes(acc, :),2));
            %random_spk_gen = exprnd(spike_range,1,size(spikes(acc, :),2) ) + 1;
            random_spk_gen = poissrnd(spike_range,1,size(spikes(acc, :),2)) + 1;
            temp_spikes = spikes(acc, :) .* random_spk_gen;
            T = conv(temp_spikes,temp_kernel);
        end
        T = T(kernel_offset:end);
        T = T(1:t);
        
        
        %----------------
        % Update matrices
        %----------------
        if spike_range > 0
            temp_spikes(temp_spikes==0) =[];
            spike_amps{acc} = temp_spikes;
        end
        
        F_mat(:,acc) = F;
        T_mat(acc,:) = T;
        cents(acc, :) = cent;
        
        
        % Termination
        if acc == num_cells
            break;
        end
        
    end
    
    %------------------
    % Add noise, make M
    %------------------

    noise = make_independent_noise(noise_std*sqrt(1-ratio_corr_noise), movie_size);
    if ratio_corr_noise > 0
        correlated_noise = make_correlated_noise(noise_std*sqrt(ratio_corr_noise), 5*mean(minmax_cell_radius), event_tau, movie_size);
        noise = noise+correlated_noise;
    end

    
    M = single(F_mat)*single(T_mat) + noise;
    M = reshape(M,h,w,t);
    
    function noise = make_independent_noise(noise_std, siz)
        noise = randn(siz(1)*siz(2),siz(3), 'single')*noise_std;
    end

    function noise = make_correlated_noise(noise_std, radius, tau, siz)
        noise = randn(siz(1), siz(2), siz(3));
        noise = spatial_bandpass(noise, radius, 2,2, 0);
        noise = reshape(noise, siz(1)*siz(2), siz(3));
        noise = conv2(1, exp(-(1:(tau*5))/tau), noise, 'same');
        noise = noise/std(noise(:)) * noise_std;
    end
end

