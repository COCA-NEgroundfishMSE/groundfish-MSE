#Function to get survey index 
get_indexData <- function(stock){

  within(stock, {

    sumCW[y] <- CN[y,] %*% waa[y,]  # dot product
    
    paaCN[y,] <- (CN[y,]) / sum(CN[y,])
   
    # calculate the predicted survey index in year y and the predicted
    # survey proportions-at-age
    IN[y,] <- get_survey(F_full=F_full[y], M=natM[y], N=J1N[y,], slxC[y,], 
                           slxI=selI, timeI=timeI, qI=qI, 
                         DecCatch=DecCatch, Tanom=Tanom[y],y=y)
    sumIN[y] <- sum(IN[y,])
    sumIW[y] <- IN[y,] %*% waa[y,]
    
    paaIN[y,] <- IN[y,] / sum(IN[y,])
    
    # calculate effort based on catchability and the implemented fishing
    # mortality. Effort not typically derived ... could go the other way
    # around and implement E as a policy and calculate F.

    effort[y] <- F_full[y] / qC
    obs_effort[y] <- get_error_idx(type=oe_effort_typ, idx=effort[y], 
                                     par=oe_effort)
    
    # Get observation error data for the assessment model
     if (y < c(fmyearIdx)){
     obs_sumCW[y] <- sumCW[y]
     }
     if (y >= (fmyearIdx)){
    obs_sumCW[y] <- get_error_idx(type=oe_sumCW_typ, 
                                    idx=sumCW[y] * ob_sumCW, 
                                    par=oe_sumCW)
     }
    
    obs_paaCN[y,] <- get_error_paa(type=oe_paaCN_typ, paa=paaCN[y,], 
                                     par=oe_paaCN)
    
    obs_sumIN[y] <- get_error_idx(type=oe_sumIN_typ, 
                                          idx=sumIN[y] * ob_sumIN, 
                                          par=oe_sumIN)
    
    # Observed index by weight is a function of the observed index and the
    # true proportions at age. This preserves the fact that the multinomial proportions at age
    # and the lognormal numbers-at-age are separate processes (which is consistent with
    # most assessment models)
    obs_sumIW[y] <- (obs_sumIN[y] * paaIN[y,]) %*% waa[y,]
    obs_paaIN[y,] <- get_error_paa(type=oe_paaIN_typ, paa=paaIN[y,], 
                                     par=oe_paaIN)
    })

  
}
      