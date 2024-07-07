function [] = plot_hyperparameter_curves(output,num)

    if nargin <2
        num = -1;
    end

    [fmap, ~] = get_quality_metric_map;
    thresholds  = output.config.thresholds;

    
    if num == -1
        metrics = output.info.cellcheck.metrics;
    elseif num == 1
        metrics = output.info.summary.classification(1).metrics;
    else
        is_bad = output.info.summary.classification(num-1).is_bad;
        metrics = output.info.summary.classification(num).metrics;
        metrics = metrics(:,~is_bad);
    end
    avg_cell_area = pi * output.config.avg_cell_radius ^ 2;
    figure
    subplot(2,4,1)
    metric      = metrics(fmap('T_maxval'), :);
    edges = [0:2:30];
    metric(isnan(metric))=0;
    metric(metric>30) = 30;
    histogram(metric, edges);
    xlabel('T min snr');
    ylabel('Number of cells')


    subplot(2,4,2)
    metric      = metrics(fmap('S_corruption'), :);
    edges = [0:0.4:10];
    metric(isnan(metric))=10;
    metric(metric>10) = 10;
    histogram(metric, edges);
    xlabel('Spatial corrupt thresh');
    ylabel('Number of cells')

    subplot(2,4,3)
    metric      = metrics(fmap('ST2_index_4'), :);
    edges = [0:0.1:1];
    metric(isnan(metric))=0;
    metric(metric>1) = 1;
    histogram(metric, edges);
    xlabel('low ST index thresh');
    ylabel('Number of cells')
    
    subplot(2,4,4)
    metric      = metrics(fmap('S_eccent'), :);
    edges = [0:0.5:10];
    metric(isnan(metric))=10;
    metric(metric>10) = 10;
    histogram(metric, edges);
    xlabel('Eccent thresh');
    ylabel('Number of cells')
    
    subplot(2,4,5)
    metric      = metrics(fmap('T_corruption'), :);
    edges = [0:.03:1];
    histogram(metric, edges);
    xlabel('Temporal corrupt thresh');
    ylabel('Number of cells')


    subplot(2,4,6)
    metric      = [metrics(fmap('S_area_1'), :),metrics(fmap('S_area_1'), :)];
    metric = metric/avg_cell_area;
    metric(isnan(metric))=0;
    metric(metric>10) = 10;
    edges = [0.1:0.1:10];
    histogram(metric, edges);
    xlabel('Lower and Upper Size limits');
    ylabel('Number of cells')

    subplot(2,4,7)
    metric      = metrics(fmap('T_dup_val'), :);
    edges = [0:0.1:1];
    histogram(metric, edges);
    xlabel('T dup corr thresh');
    ylabel('Number of cells')

     subplot(2,4,8)
    metric      = metrics(fmap('S_max_corr'), :);
    edges = [0:0.1:1];
    histogram(metric, edges);
    xlabel('S dup corr thresh');
    ylabel('Number of cells')

end