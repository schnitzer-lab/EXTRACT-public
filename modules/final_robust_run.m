function [traces,filters]=final_robust_run(M,output_in,choices)
	
	% This function runs a final robust regression on the movie via the sorted cell filters. Note that this function is not optimized for memory consumption,
	% so if you need to process in chunks, please run an outside for loop and chunk the movie only across time axis, no partitioning in space is allowed!

	% Inputs: M is the movie, output_in is the EXTRACT output from the last run of EXTRACT and choices is an array of 1s and 0s denoting cell
	% sorting output. Note that output_in should not be changed during cell-sorting, only choices array is created!

	config=output_in.config;

    config.preprocess=0;
    
    X = median(M,3);
    M = (M-X)./X;

	% do not change the partition number here, otherwise it will lead to duplicate cells!
	config.num_partitions_x=1;
	config.num_partitions_y=1;


	config.trace_output_option='raw';
	config.max_iter=0;



	filters=full(output_in.spatial_weights(:,:,logical(choices)));
	traces_in=output_in.temporal_weights(:,logical(choices));

	S_in=filters;
	config.S_init=reshape(S_in, size(S_in, 1) * size(S_in, 2), size(S_in, 3));
	config.T_init=traces_in';

	output=extractor(M,config);

	switch output_in.config.trace_output_option 
		case 'nonneg'
			output.temporal_weights=max(0,output.temporal_weights);
	end
	traces=output.temporal_weights;
end
