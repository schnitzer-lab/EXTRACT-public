function [amp1,amp2,cors] = calculate_matching_amplitudes_v2(spikes,T_g,T)


amp1 = [];
amp2 = [];
cors = [];

for i = 1:size(T_g,1)
    temp_Tg= T_g(i,:);
    temp_T = T(i,:);
    temp_spikes = spikes{i};

    temp_amp1 = [];
    temp_amp2 = [];
    
    for j = 1:size(temp_spikes,2)
        amp1 = [amp1, temp_Tg(temp_spikes(j))];
        temp_amp1 = [temp_amp1,temp_Tg(temp_spikes(j))];

        amp2 = [amp2,temp_T(temp_spikes(j))];
        temp_amp2 = [temp_amp2,temp_T(temp_spikes(j))];
        
    end
    temp_cor = corrcoef(temp_amp1,temp_amp2);
    try
    cors = [cors, temp_cor(2,1)];
    catch
    end

end