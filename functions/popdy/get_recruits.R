## recruitment functions

# The function returns the recruits. 
# Includes an AR1 process if desired -- for this option must include both
# the desired level of correlation and the previous year's observed and
# expected values (for a residual).

# type: the type of recruitment function
# 
#      *"BH" time series implementation of the Beverton Holt model
#       (i.e., that includes an autocorrelative component)
#       R = a * S / (b + S) * exp(g * TAnom_y) * 
#           exp(rho*(R_ym1-Rhat_ym1) + Rsig);
#       where R_ym1-Rhat_ym1 is the residual from the previous year.
#       par['a']: Ricker a
#       par['b']: Ricker b
#       par['g']: temperature effect g
#       par['rho']: autocorrelative component rho
#       R_ym1: observed recruitment from previous year
#       Rhat_ym1: predicted recruitment from previous year
#
#      *'HS' AGEPRO implementation of the empirical cummulative 
#       distribution function with linear decline to zero; Recruitment model 21
#       need to have input of historic recruitment in .csv file 
#       in /data/data_raw/AssessmentHistory/ must have same name as stockName
#       use only terminal 20 historic years
#       SSB_star: hockey-stick hinge
#
# par: the model parameters (see descriptions of type above). par must
#      be a matrix of four columns with named rows that correspond
#      to the parameter names listed under 'type' above.
# 
# S: the total spawning stock size -- mature individuals in weight
# 
# TAnom_y: value for the temperature anomaly in year y
# 
# pe_R: process error level for recruitment (lognormal scale)
# 
# R_ym1: observed recruitment from previous year
#       
# Rhat_ym1: predicted recruitment from previous year
# stockEnv is for one species object
# issue with SSB being called from stockEnv instead of argument input when changing to run multiple stocks -11/30/22 JJ

get_recruits <- function(type, type2, par, inputSSB, TAnom_y, pe_R, block,
                         R_ym1=NULL, Rhat_ym1=NULL, stockEnv=NULL, R_est){

  if(!type %in% c('BH', 'BHSteep', 'HS')){
    stop(paste('get_recruits: check spelling of R_typ in individual stock 
               parameter file for', stockEnv$stockName))
  }

  with(stockEnv, {

  if('rho' %in% names(par)){
    
    # Check that values for rho are between -1 and 1 as they should be for
    # correlations
    if(par['rho'] < -1 || par['rho'] > 1){
      
      stop('Rfun: par[rho] must be between 0 and 1')
      
    }
    
    # Check that if rho is provided the values for the residuals are not
    # null (the default)
    if(is.null(R_ym1) || is.null(Rhat_ym1)){
      
      stop('Rfun: if rho is given R_ym1 and Rhat_ym1 must be provided')
      
    }
    
    # Provide warning message if NAs are encountered
    if(is.na(R_ym1) || is.na(Rhat_ym1)){
      
      warning('Rfun: NA encountered in R_ym1 or Rhat_y-1 -- autocorrelation
               error not included')
      R_ym1 <- 1
      Rhat_ym1 <- 1
      
    }
    
  }else{
    
    # if rho is not provided, then set it to 0.0 and set the residuals to
    # numbers > 0 (they will be cancelled automatically since rho is zero)
    par['rho'] <- 0
    R_ym1 <- 1
    Rhat_ym1 <- 1
    
  }
  
  if(type == 'BH'){
 
    # Expected value
    Rhat <- (par['a']*inputSSB)/(1+(par['b']*inputSSB))*exp(par['g']*TAnom_y)
    Rhat <- Rhat*1000

  }
    
  else if(type == 'BHSteep'){
  
    # Note that the steepness version of the stock-recruit model requires SSBR
    # at F=0 which is a function of selectivity. Percieved selectivity can
    # change over the course of the time period according to how the assessment
    # model estimates it; however for the predicted recruitment we are only
    # interested in the realized recruitment. Thus we can just use the true
    # selectivity in the model and not worry about the estimated version.
    
    if(is.na(par['beta1'])){
      par['beta1'] <- 0
    }
    if(is.na(par['beta2'])){
      par['beta2'] <- 0
    }
    if(is.na(par['beta3'])){
      par['beta3'] <- 0
    }

    Rhat <- with(as.list(par), {
      # gamma parameterization has to do with fitting model with steepness
      # between 0 and 1. See A. Weston thesis p. 15 Eqns. 5&6.
      gamma <- -0.5 * log( (1 - 0.2) / (h - 0.2) - 1) + beta1* TAnom_y
      hPrime <- 0.2 + (1 - 0.2) / (1 + exp(-2*gamma));
      R0Prime <- R0 * exp(beta2 * TAnom_y)
      num <- 4 * hPrime * ( inputSSB / (SSBRF0) )
      den <- ( (1 - hPrime) + (5*hPrime - 1) * ( inputSSB / (R0Prime * SSBRF0) ) )
      z <-  num / den * exp(beta3 * TAnom_y)
      return(z)
    })
    

  }
    
    else if (type == 'HS'){ 
      if(stockEnv$stockName=='haddockGB'){
        Rhat <- with(as.list(par),{
          if (type2=="True"){
            #stockEnv <- within(stockEnv, {
            #assess_vals <- get_HistAssess(stock = stockEnv)
            #})
            pred<-remp(1,tail(as.numeric(stockEnv$assess_vals$assessdat$R,20)))
            
          }
          else{
            pred <- remp(1, as.numeric(R_est))
          }
          return(pred)
        })}
      else{
        Rhat <- with(as.list(par),{
          SSBhinge<-SSB_star
          if (type2=="True"){
            #stockEnv <- within(stockEnv, {
            #assess_vals <- get_HistAssess(stock = stockEnv)
            #})
            
            if (inputSSB >= SSBhinge) {
              pred <- cR * remp(1, tail(as.numeric(stockEnv$assess_vals$assessdat$R), Rnyr))
            } else if (inputSSB < SSBhinge){
              pred <-  cR * (inputSSB/SSBhinge) * remp(1, tail(as.numeric(stockEnv$assess_vals$assessdat$R), Rnyr))
            }
          }
          else{
            if (inputSSB >= SSBhinge) {
              pred <- cR * remp(1, tail(as.numeric(R_est), Rnyr))
            } 
            else if (inputSSB < SSBhinge){
              pred <-  cR * (inputSSB/SSBhinge) * remp(1, tail(as.numeric(R_est), Rnyr))
            }
          }
          return(pred)
        })}
  }
  # Autocorrelation component
  ac <- par['rho'] * log(R_ym1 / Rhat_ym1)
  
  # Random error component
  rc<-rnorm(1,mean=0,sd=pe_R)
  R <- Rhat * exp(ac + rc)
  out <- list(Rhat = unname(Rhat), R = unname(R))

  return(out)
  })}







