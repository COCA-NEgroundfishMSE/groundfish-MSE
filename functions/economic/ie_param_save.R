# Function to save the scalar ie_F, ie_bias, iecl_lower, and iecl_upper values in "stock" to the new names with _OG suffixes
ie_param_save <- function(stock){
  
  out <- within(stock, {
    ie_F_OG<- ie_F
    ie_bias_OG<- ie_bias
    iecl_lower_OG <- iecl_lower 
    iecl_upper_OG<- iecl_upper 
    
    
  })
  
  return(out)
}