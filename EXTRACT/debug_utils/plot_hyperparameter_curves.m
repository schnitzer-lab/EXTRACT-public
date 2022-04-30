function [] = plot_hyperparameter_curves(output,num)

    if nargin <2
        num =1;
    end

    [fmap, ~] = get_quality_metric_map;
    thresholds  = output.config.thresholds;


    if num ==1
        metrics = output.info.summary.classification(1).metrics;
    else
        is_bad = output.info.summary.classification(num-1).is_bad;
        metrics = output.info.summary.classification(num).metrics;
        metrics = metrics(:,~is_bad);
    end
    avg_cell_area = pi * output.config.avg_cell_radius ^ 2;
    figure
    subplot(2,3,1)
    metric      = metrics(fmap('T_maxval'), :);
    edges = [0:2:30];
    metric(isnan(metric))=0;
    metric(metric>30) = 30;
    histogram(metric, edges);
    xline(10,'--r','LineWidth',4);
    xlabel('T min snr');


    subplot(2,3,2)
    metric      = metrics(fmap('S_corruption'), :);
    edges = [0:0.4:10];
    metric(isnan(metric))=10;
    metric(metric>10) = 10;
    histogram(metric, edges);
    xline(1.5,'--g','LineWidth',4);
    xlabel('Spatial corrupt thresh');

    subplot(2,3,3)
    metric      = metrics(fmap('ST2_index_3'), :);
    edges = [0:0.1:1];
    metric(isnan(metric))=0;
    metric(metric>1) = 1;
    histogram(metric, edges);
    xline(0.01,'--r','LineWidth',4);
    xlabel('low ST index thresh');
    
    subplot(2,3,4)
    metric      = metrics(fmap('S_eccent'), :);
    edges = [0:0.5:10];
    metric(isnan(metric))=10;
    metric(metric>10) = 10;
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
    metric(isnan(metric))=0;
    metric(metric>10) = 10;
    edges = [0.1:0.1:10];
    histogram(metric, edges);
    xlabel('Lower and Upper Size limits');

end