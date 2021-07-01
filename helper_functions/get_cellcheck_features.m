function [is_attr_bad,metrics,is_elim] = get_cellcheck_features(output)
    
is_attr_bad=output.info.cellcheck.is_attr_bad;
metrics=output.info.cellcheck.metrics;
is_elim=logical(output.info.cellcheck.is_bad);

end
