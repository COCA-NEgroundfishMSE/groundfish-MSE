# the get_implementationF implements 4 types of F
#  advicenoError:  Fully recruited Fishing mortality is equal to the Advised level (F_full==F_fullAdvice)
#  adviceWithError: F_full is normally distributed with log(mean)=(F_fullAdvice+ie_bias) and log(sd)=ie_F
#  advicewithcatchbias:  Total catch is equal to the catch limit multiplied by (1+C_mult). C_mult is fixed, but there may be "change points"
#  adviceWithCatchDeviations: Total catch is uniformly distributed with between "lowerbound*catch limit" and "upperbound*catch_limit"
get_implementationF <- function(type, stock){
  valid_types<-c("advicenoError", "adviceWithError", "advicewithcatchbias","adviceWithCatchDeviations")
  
  if(type %in% valid_types==FALSE){
      stop('get_implementationF: type not recognized')
  }
  
  
  within(stock, {

    if(type == 'advicenoError'){

      F_full[y]<- F_fullAdvice[y]

    }
    if(type == 'adviceWithError'){

        # Borrowed error_idx function from survey function bank
        Fimpl <- F_fullAdvice[y] + F_fullAdvice[y]*ie_bias
        F_full[y] <- get_error_idx(type = ie_typ,
                                   idx = Fimpl,
                                   par = ie_F)
}
        # add implimentation bias to catch, need to convert from F to catch, back to F
        # get catch in numbers using the Baranov catch equation from advised F

    if(type == 'advicewithcatchbias'){
        CN_temp[y,] <- get_catch(F_full=F_full[y], M=natM[y],
                                 N=J1N[y,], selC=slxC[y,]) + 1e-3

        # Figure out the advised catch weight-at-age
        codCW[y,] <- CN_temp[y,] *  waa[y,]

        # add bias to sum catch weight

        codCW2[y] <- sum(codCW[y,]) + (sum(codCW[y,]) * C_mult)

        if(Change_point2==TRUE && yrs[y]>=Change_point_yr){
        codCW2[y] <- sum(codCW[y,])
        }

        if(Change_point3==TRUE && yrs[y]>=Change_point_yr1){
          codCW2[y] <- sum(codCW[y,]) + (sum(codCW[y,]) * 0.5)
        }

        if(Change_point3==TRUE && yrs[y]>=Change_point_yr2){
          codCW2[y] <-sum(codCW[y,])
        }

        # Determine what the fishing mortality would have to be to get
        # that biased catch level (convert biased catch back to F).
        # Update codGOM fully selected fishing mortality to that value.

        # ST method using solver;
         F_full[y] <- get_F(x = c(codCW2[y]),
                           Nv = J1N[y,],
                           slxCv = slxC[y,],
                           M = natM[y],
                           waav = waa[y,])
}

         # Using Pope's approximation;
         # codCW2 needs to be converted to at-age to use
         #
         # F_full[y] <- get_PopesF(yield = c(codCW2[y,]),
         #                                      naa = J1N[y,],
         #                                      waa = waa[y,],
         #                                      saa = slxC[y,],
         #                                      M = natM[y],
         #                                      ra = c(8))
 
    
      else if(type == 'adviceWithCatchDeviations'){
        # type == 'adviceWithCatchDeviations' is type='advicewithcatchbias', except for one difference:
        # codCW2[y] <- sum(codCW[y,]) + (sum(codCW[y,]) * C_mult)
        # C_mult is instead a random draw on a uniform distribution.
        
        CN_temp[y,] <- get_catch(F_full=F_full[y], M=natM[y],
                                 N=J1N[y,], selC=slxC[y,]) + 1e-3
        
        # Figure out the advised catch weight-at-age
        codCW[y,] <- CN_temp[y,] *  waa[y,]
        # sum catch weight
        Annual_Catch_Limit <- sum(codCW[y,])
        
        #Add the random draws from the catch deviation. iecl_type, iecl_lower,iecl_upper are set in the stockParameters file
        codCW2[y] <- get_error_idx(type = iecl_type,
                                   idx = Annual_Catch_Limit,
                                   par = c(iecl_lower, iecl_upper))
        
        
        # Determine what the fishing mortality would have to be to get
        # that biased catch level (convert biased catch back to F).
        # Update codGOM fully selected fishing mortality to that value.
        
        # ST method using solver;
        F_full[y] <- get_F(x = c(codCW2[y]),
                           Nv = J1N[y,],
                           slxCv = slxC[y,],
                           M = natM[y],
                           waav = waa[y,])
    }
  

  })

}
