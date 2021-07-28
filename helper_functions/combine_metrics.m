function [classification_cellcheck] = combine_metrics(summary)
    num_partitions = length(summary);
    
    metrics=[];
    is_bad=[];
    is_attr_bad=[];
    
    for i_part = 1:num_partitions
       is_attr_bad_this= summary(i_part).classification(end).is_attr_bad;
       is_bad_this= summary(i_part).classification(end).is_bad;
       metrics_this=summary(i_part).classification(end).metrics;
       
       is_attr_bad=[is_attr_bad is_attr_bad_this(:,logical(~is_bad_this))];
       metrics=[metrics metrics_this(:,logical(~is_bad_this))];
       is_bad = [is_bad is_bad_this(logical(~is_bad_this))];
    end
    
    classification_cellcheck.metrics=metrics;
    classification_cellcheck.is_attr_bad=is_attr_bad;
    classification_cellcheck.is_bad=is_bad;
    
end
