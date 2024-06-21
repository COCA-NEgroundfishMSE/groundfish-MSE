# Function reset the scalar ie_F, ie_bias, iecl_lower, and iecl_upper values to previously saved params.
# See ie_param_override()

# Usage: 
# for (i in 1:nstock){
#   stock[[i]]<-ie_param_reset(stock=stock[[i]])
#  }      
# 


ie_param_reset <- function(stock){
  out <- within(stock, {
    ie_F<-ie_F_OG
    ie_bias<-ie_bias_OG
    iecl_lower <-iecl_lower_OG
    iecl_upper <-iecl_upper_OG
    
    
  })
  
  return(out)
}
