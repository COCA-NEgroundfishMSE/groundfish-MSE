


# Function to concatenate multiple simulation repetitions (i.e., from
# running on the hpcc), into a single list output for analysis. simcat
# refers to concatenating the results from the simulations.
# 
# x: list of results. What you do is combine the Rdata files from the different
#    simulation runs into a single list which is the input x.
# along_dim= the dimension of the containers that you want to concatenate. see get_containers()
#  1 = replicate and 2=mproc



get_simcat <- function(x, along_dim=1){
  
  out <- list()
  for(i in 1:length(x[[1]])){
    
    z <- lapply(x, '[[', i)
    
    out[[i]] <- do.call(abind, list(z, along=along_dim))
    
  }
  
  return(out)
  
}



