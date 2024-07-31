


# Function that returns fishing mortality advice based on the Slide control rule, also known as the Ramp control rule.
# The Slide control rule is a piecewise linear function 
# When biomass is high, F is constant 
# When biomass is low,  F is a scaled by the ratio of Biomass to Breakpoint.
# 
# parpop: list containing population parameters. Must include named element
#         "B" which is a vector of biomass history. Only the last number
#         in the history is used, so could put in a vector of length 1.
# 
# FFlat: Fishing mortality rate for the "flat" portion of the function, where biomass is high. 
# 
# BBreakpoint: Biomass threshold for the breakpoint.  This is biomass level where the the control rule switches from "Flat" to the scaled portion. 
# 


get_slideHCR <- function(parpop, FFlat, BBreakpoint){
  
  if(tail(parpop$SSBhat, 1) <= BBreakpoint){

    F <- FFlat * (tail(parpop$SSBhat, 1) / BBreakpoint)
    
  }else{
    
    F <- FFlat
    
  }
  
  return(c(Fadvice = unname(F)))
  
}



