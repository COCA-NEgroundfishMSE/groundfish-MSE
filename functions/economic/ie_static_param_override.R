# Function to update the the scalar ie_F, ie_bias, iecl_lower, and iecl_upper values in "stock" based on ie_F_hat, iebias_hat, iecl_lower_hat, and iecl_upper_hat from a previous model run
# To be more general, it would be nice to update this to take two vectors as arguments like 
#      to_update_names<-c("ie_F", "ie_bias") and
#      from_source_names<-c("ie_F_hat", "iebias_hat")
#  Although I can't think of a use case for them yet.
#  Arguments are
#     stock (the list that holds all the stock parameters and results)
#     replicate: The replicate you want to read in 
#     from_model: The row from mproc that corresponds to the ie_F and ie_bias that you want to read in.  

# Usage: 
# if(mproc$ImplementationClass[m]=="StandardFisheries" & mproc$ie_override[m]=="TRUE"){
#   for (i in 1:nstock){
#  if(mproc$ie_source[m]!="Internal"){  
#     stock[[i]]<-ie_static_param_override(stock=stock[[i]],replicate=r, from_model=mproc$ie_from_model[m], stocknum=i)
#   }      
# }

ie_static_param_override <- function(stock, replicate, from_model, stocknum){
  

  # Here is the code to read in ie_F and ie_bias "externally", from an economic simulation that was run a while ago.    
  
  if(is.na(old_omvalGlobal[[stocknum]]$ie_F_hat[replicate, from_model])==TRUE){
    warning(paste0("ie_F_hat is NA in rep", replicate))
  } else {
    stock$ie_F<-old_omvalGlobal[[stocknum]]$ie_F_hat[replicate, from_model]
  }
  
  if(is.na(old_omvalGlobal[[stocknum]]$iebias_hat[replicate, from_model])==TRUE){
    warning(paste0("iebias_hat is NA in rep", replicate))
  } else{
    stock$ie_bias<-old_omvalGlobal[[stocknum]]$iebias_hat[replicate, from_model]
  }
  
  
  if(is.na(old_omvalGlobal[[stocknum]]$iecl_lower_hat[replicate, from_model])==TRUE){
    warning(paste0("iecl_lower_hat is NA in rep", replicate))
  } else{
    stock$iecl_lower<-old_omvalGlobal[[stocknum]]$iecl_lower_hat[replicate, from_model]
  }
  
  if(is.na(old_omvalGlobal[[stocknum]]$iecl_upper_hat[replicate, from_model])==TRUE){
    warning(paste0("iecl_upper_hat is NA in rep", replicate))
  } else{
    stock$iecl_upper<-old_omvalGlobal[[stocknum]]$iecl_upper_hat[replicate, from_model]
  }
  
  
  
  
  return(stock)
}