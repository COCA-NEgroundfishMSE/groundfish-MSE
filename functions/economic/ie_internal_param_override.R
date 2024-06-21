# Function to update the the scalar scalar ie_F, ie_bias, iecl_lower, and iecl_upper values in "stock" based on ie_F_hat, iebias_hat, iecl_lower_hat, and iecl_upper_hat 
# To be more general, it would be nice to update this to take two vectors as arguments like 
#      to_update_names<-c("ie_F", "ie_bias") and
#      from_source_names<-c("ie_F_hat", "iebias_hat")
#  Although I can't think of a use case for them yet.
# Arguments are
#     stock (the list that holds all the stock parameters and results)
#     from_model: The row from mproc that corresponds to the ie_F and ie_bias that you want to read in.  Only used when mproc$ie_source=="Internal" 

# Usage: 
# if(mproc$ImplementationClass[m]=="StandardFisheries" & mproc$ie_override[m]=="TRUE"){
#   for (i in 1:nstock){
#     if(mproc$ie_source[m]=="Internal"){  
#       stock[[i]]<-ie_internal_param_override(stock=stock[[i]],replicate=r, from_model=1)
#     }
#   }
# }

ie_internal_param_override <- function(stock, replicate, from_model){
  
  out <- within(stock, {
    #Replace ie_F and ie_bias with their values from the the internal source model
    if(is.na(omval$ie_F_hat[replicate, from_model])==TRUE){
      warning(paste0("ie_F_hat is NA in rep", replicate))
    } else {
      ie_F<-omval$ie_F_hat[replicate, from_model]
    }
    
    if(is.na(omval$iebias_hat[replicate, from_model])==TRUE){
      warning(paste0("iebias_hat is NA in rep", replicate))
    } else{
      ie_bias<-omval$iebias_hat[replicate, from_model]
    }

    if(is.na(omval$iecl_lower_hat[replicate, from_model])==TRUE){
      warning(paste0("iecl_lower_hat is NA in rep", replicate))
    } else{
      iecl_lower<-omval$iecl_lower_hat[replicate, from_model]
    }
    
    if(is.na(omval$iecl_upper_hat[replicate, from_model])==TRUE){
      warning(paste0("iecl_upper_hat is NA in rep", replicate))
    } else{
      iecl_upper<-omval$iecl_upper_hat[replicate, from_model]
    }
  })
  
  return(out)
}