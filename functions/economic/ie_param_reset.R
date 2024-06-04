# Function reset the scalar ie_F and ie_bias values to previously saved params.
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
  })
  
  return(out)
}
