function [] = plot_hyperparameter_curves(output)
    [fmap, ~] = get_quality_metric_map;
    thresholds  = output.config.thresholds;
    metrics = output.info.summary(1).classification.metrics;
    avg_cell_area = pi * output.config.avg_cell_radius ^ 2;
    figure
    subplot(2,3,1)
    metric      = metrics(fmap('T_maxval'), :);
    edges = [0:3:100];
    histogram(metric, edges);
    xline(10,'--r','LineWidth',4);
    xlabel('T min snr');


    subplot(2,3,2)
    metric      = metrics(fmap('S_corruption'), :);
    edges = [min(metric):(max(metric)-min(metric))/30:max(metric)];
    histogram(metric, edges);
    xline(0.7,'--g','LineWidth',4);
    xlabel('Spatial corrupt thresh');

    subplot(2,3,3)
    metric      = metrics(fmap('ST2_index_3'), :);
    edges = [min(metric):(max(metric)-min(metric))/30:max(metric)];
    histogram(metric, edges);
    xline(0.01,'--r','LineWidth',4);
    xlabel('low ST index thresh');
    
    subplot(2,3,4)
    metric      = metrics(fmap('S_eccent'), :);
    edges = [min(metric):(max(metric)-min(metric))/30:max(metric)];
    histogram(metric, edges);
    xline(6,'--g','LineWidth',4);
    xlabel('Eccent thresh');
    
    subplot(2,3,5)
    metric      = metrics(fmap('T_corruption'), :);
    edges = [0:.03:1];
    histogram(metric, edges);
    xline(0.7,'--g','LineWidth',4);
    xlabel('Temporal corrupt thresh');


    subplot(2,3,6)
    metric      = [metrics(fmap('S_area_1'), :),metrics(fmap('S_area_1'), :)];
    metric = metric/avg_cell_area;
    edges = [min(metric):(max(metric)-min(metric))/30:max(metric)];
    histogram(metric, edges);
    xlabel('Lower and Upper Size limits');

end




