#Script reads in end_rng_XX.rds and finds the last RNG state with the last complete replicate runs 
#and restores that RNG state to continue resplicates at the MPROC loop 

  end_rng_file_path = file.info(list.files(path=file.path(econ_results_location), pattern = "end_rng", full.names = TRUE))
  end_rng_file_path = rownames(end_rng_file_path)[which.max(end_rng_file_path$mtime)]
  end_rng = readRDS(end_rng_file_path)
  
  end_rng = end_rng[lengths(end_rng) != 0] 
  
  end_rng = data.table(t(setDT(end_rng, FALSE)))
  
  max_rep = as.numeric(max(end_rng$V1))
  
  max_reps = end_rng [V1==max_rep]
  total_reps = length(unique(mproc$EconData))*(end_sim - start_sim +1 )
  
  if (count(max_reps)==total_reps){
    #ie last replicate is complete (models*years) 
    start_rep = max_rep + 1
    
    #selects RNG state of the last model ran in a complete replicate (models*years)
    .Random.seed = as.integer(max_reps[nrow(max_reps),5:ncol(max_reps)])
  } else {
    #ie last replicate is incomplete, only contains partial results (less than models*years)
    start_rep = max_rep
    
    #Restore RNG state to the last model ran in the last complete replicate (models*years)
    max_reps_1 = end_rng [V1==(max_rep-1)]
    .Random.seed = as.integer(max_reps_1[nrow(max_reps_1),5:ncol(max_reps_1)])
  }
  
  rm("end_rng_file_path", "end_rng", "max_rep", "max_reps", "total_reps", "max_reps_1")
  
  