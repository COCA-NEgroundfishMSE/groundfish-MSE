# Function to save the scalar ie_F and ie_bias values in "stock" to the new names with _OG suffixes
ie_param_save <- function(stock){
  
  out <- within(stock, {
    ie_F_OG<- ie_F
    ie_bias_OG<- ie_bias
    
  })
  
  return(out)
}