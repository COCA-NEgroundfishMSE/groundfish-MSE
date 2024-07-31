# The application of harvest control rules
#
# parmgt: a 1-row data frame of management parameters. The operational
#         component of parmgt for this function is the (1-row) column
#         "HCR". Options are:
#  
#  **constF**: The harvest control rule is simply a flat line, in other words no matter what in each year 
#F will be determined by the F reference point.
#
#  **simplethresh**: A simple threshold model. If the estimated SSB is larger than the SSB reference point
#then the advice will be fishing at the F reference point. If the estimated SSB is smaller than the SSB 
#reference point F will be 0.
#
#  **slide**: A sliding control rule.  Similer to simplethresh, except when the estimated SSB is lower 
#than the SSB reference point fishing is reduced though not all the way to zero. Instead, a line is drawn
#between [SSBRefPoint, FRefPoint] and [0, 0] and the advice is the value for F on that line at the 
#corresponding estimate of SSB.
#
#  **pstar**: The P* method. The aim of this HCR option is to avoid overfishing by accounting for 
#scientific uncertainty with a probabilistic approach. In this scenario, the P* approach (Prager & 
#Shertzer, 2010) is used to derive target catch. The P* method derives target catch as a low percentile of
#projected catch at the OFL, to allow for scientific uncertainty. The distribution of the catch at the OFL
#was assumed to follow a lognormal distribution with a CV of 1 (Wiedenmann et al., 2016). The target catch
#will correspond to a probability of overfishing no higher than 50% (P* <0.5) in accordance with the 
#National Standard 1 guidelines.
#
#  **step**: Step in fishing mortality. If the SSB decreased below the biomass threshold, this HCR uses a
#target F of 70% FMSY that has recently been applied to New England groundfish as a default Frebuild. If 
#the SSB never decreased below the biomass threshold or increased to over SSBMSY after dropping below the 
#biomass threshold, this HCR uses a target F at the F threshold. This alternative directly emulates an HCR
#used for some New England groundfish. 
#                        
# parpop: named ist of population parameters (vectors) needed for the 
#         simulation including selectivity (sel), weight-at-age (waa),
#         recruitment (R), maturity (mat) and natural mortality (M).
#         Natural mortality can be a vector or a scalar. Vectors have
#         one value per age class.
#         
# Rlast: a vector of length 2 representing the Fmsy and Bmsy reference points
#        that were used in the previous year of the simulation. The reason
#        for this is so you can evaluate management procedures that only
#        update reference points once every N number of years.
#        
# evalRP: True/False variable indicating whether reference points should
#         be evaluated at all -- if not then just use RPlast. 

get_nextF <- function(parmgt, parpop, parenv, RPlast, evalRP, stockEnv){
  # A general application of national standard 1 reference points. There
  # are different ways to grab the F reference point and the B reference
  # point and those will be implemented in get_FBRP

  if(parmgt$ASSESSCLASS == 'CAA' || parmgt$ASSESSCLASS == 'ASAP'){
    
    parpopF<-parpop
    
    # for GOM cod, Mramp model uses M = 0.2 for status determination
    if (stockEnv$stockName=='codGOM' & stockEnv$M_typ == 'ramp'){
    parpopF$M<-rep(0.2,9)
    }
    
    parpopF$switch<-FALSE
    
    #Estimate F reference point
    Fref <- get_FBRP(parmgt = parmgt, parpop = parpopF, 
                     parenv = parenv, Rfun_lst = Rfun_BmsySim, 
                     stockEnv = stockEnv)
    
    #Determine True F reference point
    parmgtT<-parmgt
    parpopT<-parpop
    
    # for GOM cod, Mramp model uses M = 0.2 for status determination
    if (stockEnv$stockName=='codGOM' & stockEnv$M_typ == 'ramp'){
    parpopT$M<-rep(0.2,9)
    }
    
    parpopT$switch<-TRUE
    
    #Use OM values
    parpopT$J1N<-stockEnv$J1N[1:(y-1),]
    parpopT$selC<-stockEnv$selC
    parpopT$R<-stockEnv$R[1:(y-1)]
    stockEnvT<-stockEnv
    stockEnvT$R_mis<-FALSE
    
    FrefT <- get_FBRP(parmgt = parmgtT, parpop = parpopT, #Also calculate the true Fmsy
                     parenv = parenv, Rfun_lst = Rfun_BmsySim, 
                     stockEnv = stockEnvT)
    
    # if using forecast start the BMSY initial population at the equilibrium
    # FMSY level (before any temperature projections). This is consistent
    # with how the Fmsy is calculated.
    parpopUpdate <- parpopF
    parpopUpdateT <- parpopT
    if(parmgt$RFUN_NM == 'forecast'){
      parpopUpdate$J1N <- Fref$equiJ1N_MSY
    }
    
    #Estimate biomass reference point
    stockEnvT$R_mis<-TRUE
    Bref <- get_BBRP(parmgt = parmgt, parpop = parpopUpdate, 
                     parenv = parenv, Rfun_lst = Rfun_BmsySim,
                     FBRP = Fref[['RPvalue']], stockEnv = stockEnv)
    
    #Determine true biomass reference point
    stockEnvT<-stockEnv
    stockEnvT$R_mis<-FALSE
    BrefT <- get_BBRP(parmgt = parmgtT, parpop = parpopUpdateT, #Also calculate the true Bmsy
                     parenv = parenv, Rfun_lst = Rfun_BmsySim,
                     FBRP = FrefT[['RPvalue']], stockEnv = stockEnvT)
    
    #Save reference points if it is the correct year to do so or else use previous reference ponits in catch advice
    if(evalRP){
      FrefRPvalue <- Fref[['RPvalue']]
      BrefRPvalue <- Bref[['RPvalue']]
      FrefTRPvalue <- FrefT[['RPvalue']]
      BrefTRPvalue <- BrefT[['RPvalue']]
    }else{
      FrefRPvalue <- RPlast[1]
      BrefRPvalue <- RPlast[2]
      FrefTRPvalue <- FrefT[['RPvalue']]
      BrefTRPvalue <- BrefT[['RPvalue']]
    }

    #Determine overfished threshold and target fishing mortality
    BThresh <- BrefScalar * BrefRPvalue
    FThresh <- FrefScalar * FrefRPvalue
    
    # Determine whether the population is perceived to be overfished 
    # Determine whether a population is perceived to be rebuilt  
    # Determine whether overfishing is perceived to be occurring
    
    overfished <- ifelse(tail(parpop$SSBhat,1) < BThresh, 1, 0)
    rebuilt <- ifelse(tail(parpop$SSBhat,1) >= BrefRPvalue, 1, 0)
    overfishing <- ifelse(tail(parpop$Fhat,1) > FrefRPvalue, 1, 0) #MDM

    # Determine if stock is in rebuilding plan. 
    #     Stock is in a rebuilding plan if it is overfished
    #     Stock is in a rebuilding plan if it was in a rebuilding plan last year and stock is not rebuilt this year.
    inrebuildingplan<-ifelse(overfished==1, 1, 
                             ifelse(parpop$InRebuild==1 & rebuilt==0,1,0)
    )
    
        
    #Ramp HCR
    if(tolower(parmgt$HCR) == 'slide'){
      F <- get_slideHCR(parpop, FFlat=FThresh, BBreakpoint=BThresh)['Fadvice']
    }
    
    #Ramp HCR that is rebuilding Aware
    if(tolower(parmgt$HCR) == 'sliderebuildaware'){
      
      if(inrebuildingplan==0){
        F <- get_slideHCR(parpop, FFlat=FrefRPvalue*parmgt$HCR_PAR1, BBreakpoint=BThresh)['Fadvice']
      }
      else if (inrebuildingplan==1){
        F <- get_slideHCR(parpop, FFlat=FrefRPvalue*parmgt$HCR_PAR2, BBreakpoint=BThresh)['Fadvice']
      }
    }

    #Threshold HCR
    else if(tolower(parmgt$HCR) == 'simplethresh'){
      # added small value to F because F = 0 causes some estimation errors
      F <- ifelse(tail(parpop$SSBhat, 1) < BThresh, 0, FThresh)+1e-4
    }

    #Threshold HCR that is rebuilding Aware
    else if(tolower(parmgt$HCR) == 'simplethreshrebuildaware'){

      if(inrebuildingplan==0){
        F <- FrefRPvalue*parmgt$HCR_PAR1 
      }
      else if (inrebuildingplan==1){
        F <- parmgt$HCR_PAR2
      }
    }
    
    
        
    #Constant fishing mortality HCR
    else if(tolower(parmgt$HCR) == 'constf'){
      F <- FThresh
    }
    
    #Constant fishing mortality HCR that is rebuilding Aware
    else if(tolower(parmgt$HCR) == constfrebuildaware){
      if(inrebuildingplan==0){
        F <- FrefRPvalue*parmgt$HCR_PAR1 
      }
      else if (inrebuildingplan==1){
        F <- FrefRPvalue*parmgt$HCR_PAR0
      }
    }
    
    #Step in fishing mortality HCR
    else if(tolower(parmgt$HCR) == 'step'){
      if (y==fmyearIdx & overfished== 1){F<-FrefRPvalue*0.7}
      else if (y==fmyearIdx & overfished== 0){F<-FThresh}
      else if (y>fmyearIdx & overfished== 1){F<-FrefRPvalue*0.7}
      else if (y>fmyearIdx & overfished== 0){
        if(any(stockEnv$OFdStatus==1,na.rm=T)& tail(parpop$SSBhat,1)<BrefRPvalue){F<-FrefRPvalue*0.7}
        else{F<-FThresh}}
    }
    
    #Projections
    if(tolower(parmgt$projections) == 'true'){
      if ((y-fmyearIdx) %% as.numeric(tolower(parmgt$AssessFreq)) == 0){
      parmgtproj<-parmgt
      parmgtproj$RFUN_NM<-"forecast"
      catchproj<-matrix(ncol=2,nrow=100)
      parpopproj<-parpop
      parpopproj$SSBhat<-stockEnv$res$SSB
      parpopproj$R<-stockEnv$res$N.age[,1]
      parpopproj$J1N<-tail(stockEnv$res$N.age,1)
      parpopproj$catch<-stockEnv$res$catch.obs
      
      #Use Fmsy for F in projections for P* HCR
      if(tolower(parmgt$HCR) == 'pstar'){F<-FrefRPvalue}
      
      #If weight-at-age is misspecified, make it misspecified in projections
      if(stockEnv$waa_mis=='TRUE'){
        parpopproj$waa<-stock[[1]]$waa[1,]
      }
      
      #Projections differ if there is a lag or no lag in information to the assessment
      for (i in 1:100){
          if(mproc[m,'Lag'] == 'TRUE'){
          catchproj[i,]<-get_proj(type = 'current',
                                  parmgt = parmgtproj, 
                                  parpop = parpopproj, 
                                  parenv = parenv, 
                                  Rfun = Rfun_BmsySim$forecast,
                                  F_val = F,
                                  ny = 200,
                                  stReportYr = 2,
                                  stockEnv = stockEnv)$sumCW
          }
          else if(mproc[m,'Lag'] == 'FALSE'){
          catchproj[i,]<-get_projnolag(type = 'current',
                                  parmgt = parmgtproj, 
                                  parpop = parpopproj, 
                                  parenv = parenv, 
                                  Rfun = Rfun_BmsySim$forecast,
                                  F_val = F,
                                  ny = 200,
                                  stReportYr = 2,
                                  stockEnv = stockEnv)$sumCW
          }
      }
  
      #Get catch advice 
      catchproj<-c(median(catchproj[,1]),median(catchproj[,2]))
      
      #Determine catch advice for P* HCR
      if(tolower(parmgt$HCR) == 'pstar'){
        P<-calc_pstar(0.4,tail(parpop$SSBhat,1)/BThresh)
        CV<-1
        catchproj[1]<-calc_ABC(catchproj[1],P,CV)
        catchproj[2]<-calc_ABC(catchproj[2],P,CV)
      }
      
      #If the minimum catch constraint is on, make sure catch advice is not below that constraint
      if(tolower(parmgt$mincatch) == 'true'){
        
      #Use the stock name from to read in the   
      bycatchfile<-paste0(stockEnv$stockName,"_Discard.csv")
      bycatch<-read.csv(paste0(getwd(),"/data/data_raw/AssessmentHistory/",bycatchfile))
      mincatch<-min(tail(bycatch$Discard),10)
        
        
      if (catchproj[1]>mincatch & catchproj[2]>mincatch){mincatchcon<-0}
      if (catchproj[1]<mincatch){
        catchproj[1]<-mincatch
        mincatchcon<-1
      }
      if (catchproj[2]<mincatch){
        catchproj[2]<-mincatch
        mincatchcon<-1
      }
      }
      
      #If catch variation constraint is on, make sure catch advice does not vary more than 20% from year to year
      if(tolower(mproc$varlimit) == 'true'){
        if(((catchproj[1]-(stockEnv$sumCW[y-1]*stockEnv$ob_sumCW))/catchproj[1])*100<(-20)){
          catchproj[1]<-(stockEnv$sumCW[y-1]*stockEnv$ob_sumCW)-((stockEnv$sumCW[y-1]*stockEnv$ob_sumCW)*.2)}
        if(((catchproj[1]-(stockEnv$sumCW[y-1]*stockEnv$ob_sumCW))/catchproj[1])*100>20){
          catchproj[1]<- (stockEnv$sumCW[y-1]*stockEnv$ob_sumCW)+((stockEnv$sumCW[y-1]*stockEnv$ob_sumCW)*.2)}
        if(((catchproj[2]-catchproj[1])/catchproj[2])*100<(-20)){
          catchproj[2]<- catchproj[1]-(catchproj[1]*.2)}
        if(((catchproj[2]-catchproj[1])/catchproj[2])*100>20){
          catchproj[2]<- catchproj[1]+(catchproj[1]*.2)}
      }
      
      #Estimate F to make sure catch advice is not over the perceived OFL
      Fest<-get_estF(catchproj=catchproj[1],parmgtproj=parmgtproj,parpopproj=parpopproj,parenv=parenv,Rfun=Rfun,stockEnv=stockEnv)
      
      #If catch advice is over the perceived OFL, catch advice becomes the catch at the perceived OFL
      if (Fest>FrefRPvalue){
        catchproj<-matrix(ncol=2,nrow=100)
        for (i in 1:100){
            catchproj[i,]<-get_proj(type = 'current',
                                    parmgt = parmgtproj, 
                                    parpop = parpopproj, 
                                    parenv = parenv, 
                                    Rfun = Rfun_BmsySim$forecast,
                                    F_val = FrefRPvalue,
                                    ny = 200,
                                    stReportYr = 2,
                                    stockEnv = stockEnv)$sumCW}
        catchproj<-c(median(catchproj[,1]),median(catchproj[,1]))
        if(tolower(mproc$varlimit) == 'true'){
          if(((catchproj[2]-catchproj[1])/catchproj[2])*100>20){
            catchproj[2]<- catchproj[1]+(catchproj[1]*.2)}
        }
      }
      
      #Get F for the OM based on catch advice
      F <- get_F(x = catchproj[1],
                   Nv = stockEnv$J1N[y,], 
                   slxCv = stockEnv$slxC[y,], 
                   M = stockEnv$natM[y], 
                   waav = stockEnv$waa[y,])
      }
      
      #If it is on an 'off' year (assessment does not occur) use catch advice from the previous projections second year
      else{
      F <- get_F(x = stockEnv$catchproj[2],
                 Nv = stockEnv$J1N[y,], 
                 slxCv = stockEnv$slxC[y,], 
                 M = stockEnv$natM[y], 
                 waav = stockEnv$waa[y,])
      catchproj<-stockEnv$catchproj
      }
    }
    
    #No projections (no projected catch advice)
    if(tolower(parmgt$projections) == 'false'){catchproj<-NA}
  
    if (F>2){F<-2}#Not letting actual F go over 2

    out <- list(F = F, RPs = c(FrefRPvalue, BrefRPvalue,FrefTRPvalue, BrefTRPvalue), 
                ThresholdRPs = c(FThresh, BThresh), OFdStatus = overfished,
                OFgStatus = overfishing, catchproj=catchproj, inrebuildingplan=inrebuildingplan) #AEW
    
  #Plan B Approach
  }else if(parmgt$ASSESSCLASS == 'PLANB'){
    
    # Find the recommended level for catch in weight
    CWrec <- tail(parpop$obs_sumCW, 1) * parpop$mult
    
    #### NEXT MIGRATE THE WEIGHT TO A FISHING MORTALITY
    #### you know what the selectivity is going to be 
    #### (use the real one here) and you know what the weight is
    #### going to be (use the real one) so drive the F as hard as
    #### required in each of the age classes until you land on
    #### the desired catch biomass.
    
    # Calculate what the corresponding true F is that matches with
    # the actual biomass-at-age in the current year
    trueF <- get_F(x = CWrec,
                  Nv = parpop$Ntrue_y, 
                  slxCv = parpop$slxCtrue_y, 
                  M = parpop$Mtrue_y, 
                  waav = parpop$waatrue_y)
    
    out <- list(F = trueF, RPs = c(NA, NA), OFdStatus=NA,
                OFgStatus = NA, inrebuildingplan=NA) #AEW
    
  }else{
    
    stop('Assessment class not recognized')
    
  }
  
}




