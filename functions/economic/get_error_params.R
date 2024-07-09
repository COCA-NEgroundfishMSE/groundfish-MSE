
# Function to return the mean and sdlog. This 'inverts' the get_implementationF() function for the 'adviceWwithError" model runs.
# Modified from MASS::densfun
# Didn't want to load a new library for one small function.
# I'm using ieF_hat to denote the sdlog, which is related to how different F_full is from the bias-adjusted F_fullAdvice
# I'm using iebias_hat to denote the point estimate of ie_b -- the average difference between F_fullAdvice and the F_full.

# iecl_lower_hat and iecl_upper_hat are the smallest and largest values of the ratio of catch:ACL


get_error_params <- function(stock, fit_ie,firstyear, lastyear){
  valid_types<-c("lognorm", "uniform")
  
  if(fit_ie %in% valid_types==FALSE){
    stop('get_implementationF: fit_ie not recognized')
  }
  
  if (fit_ie== "lognorm"){
    
  out <- within(stock, {
    
    # Fit the lognormal 
      errs<-F_full[firstyear:lastyear]/F_fullAdvice[firstyear:lastyear]
      
      if (any(errs <= 0)){ 
        stop("need positive values to fit a log-Normal")
      }
      iefit_n <- length(errs)
      iefit_lx <- log(errs)
      iefit_mx <- mean(iefit_lx)
      
      #ieF_hat is simply the sdlog term.
      omval$ie_F_hat[r,m]<-ie_F_hat <- sqrt((iefit_n - 1)/iefit_n) * sd(iefit_lx)
      omval$iebias_hat[r,m]<-  iebias_hat<- exp(iefit_mx)-1
   })
  
  }else if(fit_ie=="uniform") {
    out <- within(stock, {
      catch_errs<-sumCW[firstyear:lastyear]/ACL[firstyear:lastyear]
      omval$iecl_lower_hat [r,m]<-iecl_lower_hat  <- min(catch_errs)
      omval$iecl_upper_hat  [r,m]<-iecl_upper_hat   <- max(catch_errs)
    })
  }
  
  return(out)
  
}




###########From get_implementation_F.R 
#   Borrowed error_idx function from survey function bank
#   Fimpl <- F_fullAdvice[y] + F_fullAdvice[y]*ie_bias
#   F_full[y] <- get_error_idx(type = ie_typ,
#                               idx = Fimpl,
#                               par = ie_F)

# From get_error_idx
#
#   idxE <- rlnorm(1, meanlog = log(idx), sdlog = par)
#
# iebias_hat is the estimate of ie_bias
# ie_F_hat is the estimate of ie_F
