function [traces]=final_robust_run(output_in, M)
	
	% This function runs a final robust regression on the movie via the sorted cell filters. Note that this function is not optimized for memory consumption,
	% so if you need to process in chunks, please run an outside for loop and chunk the movie only across time axis, no partitioning in space is allowed!

	config=output_in.config;



	% do not change the partition number here, otherwise it will lead to duplicate cells!
	config.num_partitions_x=1;
	config.num_partitions_y=1;


	config.trace_output_option='raw';
	config.max_iter=0;


	S_in=full(output_in.spatial_weights);
	config.S_init=reshape(S_in, size(S_in, 1) * size(S_in, 2), size(S_in, 3));
	config.T_init=output_in.temporal_weights';

	output=extractor(M,config);

	switch output_in.config.trace_output_option 
		case 'nonneg'
			output.temporal_weights=max(0,output.temporal_weights);

	traces=output.temporal_weights;
end