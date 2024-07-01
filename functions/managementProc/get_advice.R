get_advice <- function(stock){
  # prepare data for assessment
  tempStock <- get_tmbSetup(stock = stock)

  #### Run assessment model####

  # Run the CAA assessment
  if(mproc[m,'ASSESSCLASS'] == 'CAA'){
  if ((y-fmyearIdx) %% mproc[m,'AssessFreq'] == 0){
  tempStock <- get_caa(stock = tempStock)}
  else {get_caa(stock = tempStock)}
  }

  # Run the PlanB assessment
  if(mproc[m,'ASSESSCLASS'] == 'PLANB'){
  if ((y-fmyearIdx) %% mproc[m,'AssessFreq'] == 0){
  tempStock <- get_planB(stock = tempStock)}
  else{get_planB(stock = tempStock)}
  }

  # Run ASAP assessment
  if(mproc[m,'ASSESSCLASS'] == 'ASAP'){
    if ((y-fmyearIdx) %% mproc[m,'AssessFreq'] == 0){
    tempStock <- get_ASAP(stock = tempStock)}
    else{
      get_ASAP(stock = tempStock)}
  }

# Was the assessment successful?
  tempStock <- within(tempStock, {
    conv_rate[y] <- ifelse((mproc[m,'ASSESSCLASS'] == 'CAA' &&
                      class(opt) != 'try-error') ||
                     (mproc[m,'ASSESSCLASS'] == 'PLANB' &&
                        class(planBest) != 'try-error') ||
                     (mproc[m, 'ASSESSCLASS'] == 'ASAP' &&
                        asapEst == 0), 1, 0)
  })

  # Retrieve the estimated SSB (necessary for advice) &
  # Vary the parpop depending on the type of assessment model.

    if(mproc[m,'ASSESSCLASS'] == 'CAA'){
      tempStock <- within(tempStock, {
        SSBaa <- rep$J1N * get_dwindow(waa, sty, y-1) * get_dwindow(mat, sty, y-1)
        SSBhat <- apply(SSBaa, 1, sum)
        parpop <- list(waa = tail(rep$waa, 1) / caaInScalar,
                       sel = tail(rep$slxC, 1),
                       M = tail(rep$M, 1),
                       mat = mat[y-1,],
                       R = rep$R * caaInScalar,
                       SSBhat = SSBhat * caaInScalar,
                       J1N = rep$J1N * caaInScalar,
                       Rpar = Rpar,
                       Fhat = tail(rep$F_full, 1))
      })
    }

    if(mproc[m,'ASSESSCLASS'] == 'PLANB'){
      tempStock <- within(tempStock, {
        parpop <- list(obs_sumCW = tmb_dat$obs_sumCW,
                       mult = planBest$multiplier,
                       waatrue_y = waa[y-1,],
                       Ntrue_y = J1N[y-1,],
                       Mtrue_y = M,
                       slxCtrue_y = slxC[y-1,])
      })
    }

    if(mproc[m,'ASSESSCLASS'] == 'ASAP'){
      tempStock <- within(tempStock, {
        parpop <- list(waa = tail(res$WAA.mats$WAA.catch.fleet1, 1),
                       sel = tail(res$fleet.sel.mats$sel.m.fleet1, 1),
                       M = tail(res$M.age, 1),
                       mat = res$maturity[1,],
                       R = res$SR.resids$recruits,
                       SSBhat = res$SSB,
                       J1N = tail(res$N.age,1),                 
                       Rpar = Rpar,
                       Rpar_mis= Rpar_mis,
                       Fhat = tail(res$F.report, 1))
      })
    }
tempstock$parpop$InRebuild<-stock$InRebuildingPlan[y-1]
# Calculate Mohn's Rho values
  
  if(y > fmyearIdx){
      tempStock <- get_MohnsRho(stock = tempStock)
      cat('Rho calculated.')
      
      #Rho-adjustment if that option is turned on
      
      tempStock<-within(tempStock,{
      if(mproc[m,'rhoadjust'] == 'TRUE' & Mohns_Rho_SSB[y]>0.15){
          parpop$SSBhat[length(parpop$SSBhat)]<-parpop$SSBhat[length(parpop$SSBhat)]/(Mohns_Rho_SSB[y]+1)}
      })

      #Calculate relative Error
      tempStock <- get_relError(stock = tempStock)}

    # Environmental parameters
    parenv <- list(tempY = temp,
                   Tanom = Tanom,
                   yrs = yrs, # management years
                   yrs_temp = yrs_temp, # temperature years
                   y = y-1)

    #### Get ref points & assign F & get catch advice ####

    if( y == fmyearIdx ||
        mproc[m,'ASSESSCLASS'] == 'PLANB' ||
        (y > fmyearIdx &
          (y-fmyearIdx) %% mproc[m,'RPInt'] == 0 ) ){

      gnF <- get_nextF(parmgt = mproc[m,], parpop = tempStock$parpop,
                       parenv = parenv,
                       RPlast = NULL, evalRP = TRUE,
                       stock = tempStock)

      tempStock$RPmat[y,] <- gnF$RPs
      tempStock$catchproj <- gnF$catchproj

    }else{
      # Otherwise use old reference points to calculate stock status
      
        gnF <- get_nextF(parmgt = mproc[m,], parpop = tempStock$parpop,
                         parenv = parenv,
                         RPlast = tempStock$RPmat[y-1,], evalRP = FALSE,
                         stock = tempStock)
        tempStock$RPmat[y,] <- tempStock$RPmat[y-1,]
    }
    
    # Report overfished status (based on previous year's data)
    tempStock <- within(tempStock, {
      OFdStatus[y-1] <- gnF$OFdStatus

    # Report overfishing status
      OFgStatus[y-1] <- gnF$OFgStatus

    # Report Rebuilding Plan status. The time index is purposefully different from OFdStatus and OFgStatus
      InRebuildingPlan[y] <- gnF$inrebuildingplan
      
      
    # Report maximum gradient component for CAA model
      mxGradCAA[y-1] <- ifelse(mproc[m,'ASSESSCLASS'] == 'CAA',
                               yes = rep$maxGrad,
                               no = NA)

    # Tabulate advice (plus small constant)
      adviceF <- gnF$F + 1e-5

      # Calculate expected J1N using parameters from last year's assessment
      # model (i.e., this is Dec 31 of the previous year). Recruitment is
      # just recruitment from the previous year. This could be important
      # depending on what the selectivity pattern is, but if age-1s are
      # not very selected it won't matter much.
      
      if(mproc$ASSESSCLASS[m] != 'PLANB'){ 
        J1Ny <- get_J1Ny(J1Ny0 = tail(parpop$J1N, 1),
                         Zy0 = parpop$Fhat * parpop$sel + parpop$M,
                         Ry1 = tail(parpop$R, 1)) # last years R
      }

      quota <- get_catch(F_full = adviceF, M = natM[y], N = J1N[y,], selC = slxC[y,])
      quota <- quota %*% waa[y,]
      F_fullAdvice[y] <- adviceF
      ACL[y] <- quota

    })

  return(tempStock)

}
