function indices = select_indices(n, num_partitions, idx_partition)
    sp = ceil(n / num_partitions);
    idx_begin = max(1, (idx_partition-1) * sp + 1);
    idx_end = min(n, idx_partition * sp);
    indices = idx_begin:idx_end;