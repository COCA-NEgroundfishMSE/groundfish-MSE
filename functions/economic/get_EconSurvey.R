#for(i in 1:nstock){
  # Specific "survey" meant to track the population on Jan1
  # for use in the economic submodel. timeI=0 implies Jan1.
  # Weights inherit the units of waa, which are in metric tons/individual at this point. 
get_EconSurvey <- function(stock){
  
  out<- within(stock, {
    EconIN[y,] <- get_survey(F_full=0, M=0, N=J1N[y,], slxC[y,],
                             slxI=selI, timeI=0, qI=qI,
                             DecCatch=DecCatch, Tanom=Tanom[y],y=y)
    EconIN[y,]<-EconIN[y,] * trawl_to_econ_multiplier #Only need to do the trawl to econ survey adjustment here, because everything else depends on it.
    sumEconIN[y] <- sum(EconIN[y,])
    sumEconIW[y] <- sum(EconIN[y,] * waa[y,])
    paaEconIN[y,] <- EconIN[y,] / sum(EconIN[y,])
    
    obs_sumEconIN[y] <- get_error_idx(type=oe_sumIN_typ, 
                                      idx=sumEconIN[y] * ob_sumIN, 
                                      par=oe_sumIN)
    obs_sumEconIW[y] <- (obs_sumEconIN[y] * paaEconIN[y,]) %*% waa[y,] 
    
    
    
  })
  return(out)
  
}
