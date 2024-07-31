# For simplicity, have one list that goes through comparing
# the assessment model results with the true values and then have
# another object that will just hold the values themselves.  Makes
# things easier for analysis of results

## Filling the simpler arrays with just the OM values
## Note that nomyear is a function of "rburn" in the set_om_parameters.R
## file. rburn ensures that you are starting at least part-way into the
## management time-period so you can see the response. It is set pretty
## arbitrarily though.

get_fillRepArrays <- function(stock){

  out <- within(stock, {
    omval$N[r,m,] <- rowSums(J1N)
    omval$SSB[r,m,] <- SSB
    omval$R[r,m,] <- R
    omval$F_full[r,m,] <- F_full
    omval$sumCW[r,m,] <- sumCW #Catch of fish, metric tons
    omval$OFdStatus[r,m,] <- OFdStatus
    omval$InRebuildingPlan [r,m,] <- InRebuildingPlan
    omval$mxGradCAA[r,m,] <- mxGradCAA
    omval$F_fullAdvice[r,m,] <- F_fullAdvice #AEW
    omval$ACL[r,m,] <- ACL #AEW
    omval$OFgStatus[r,m,] <- OFgStatus #AEW
    omval$SSB_cur[r,m,] <- SSB_cur #AEW
    omval$natM[r,m,] <- natM #AEW
    
    
    omval$sumEconIW[r,m,y]<-sumEconIW[y] # "Economic" trawl survey biomass, metric tons per tow.
    
    # annPercentChange not true vector -- just repeated values. This needs
    # to be calculated after the run so that the appropriate time windows
    # can be used.
    
    omval$annPercentChange[r,m,] <- NA # placeholder -- calculated later
    meanSizeCN <- sapply(1:nrow(CN), 
                         function(x) laa[x,] %*% paaCN[x,])
    omval$meanSizeCN[r,m,] <- meanSizeCN
    meanSizeIN <- sapply(1:nrow(CN), 
                         function(x) laa[x,] %*% paaIN[x,])
    omval$meanSizeIN[r,m,] <- meanSizeIN
    omval$FPROXY[r,m,] <- RPmat[,1]
    omval$SSBPROXY[r,m,] <- RPmat[,2]
    omval$FPROXYT[r,m,] <- RPmat[,3]
    omval$SSBPROXYT[r,m,] <- RPmat[,4]
    
    if(y>=fmyearIdx){
    omval$FRATIO[r,m,y] <- stock$res$F.report[length(stock$res$F.report)]/RPmat[,1][y]
    omval$SSBRATIO[r,m,y] <- stock$res$SSB[length(stock$res$SSB)]/RPmat[,2][y]
    omval$FRATIOT[r,m,y] <- stock$F_full[y]/RPmat[,3][y]
    omval$SSBRATIOT[r,m,y] <- stock$SSB[y]/RPmat[,4][y]
    }
    
    
    if(mproc[m,'rhoadjust'] == 'TRUE' & y>fmyearIdx & Mohns_Rho_SSB[y]>0.15){
    omval$FRATIO[r,m,y] <- (stock$res$F.report[length(stock$res$F.report)]/(Mohns_Rho_F[y]+1))/RPmat[,1][y]
    omval$SSBRATIO[r,m,y] <-(stock$res$SSB[length(stock$res$SSB)]/(Mohns_Rho_SSB[y]+1))/RPmat[,2][y]
    }
    if(y == nyear){
      # Determine whether additional years should be added on to the
      # beginning of the series
      if(nyear > length(cmip_dwn$YEAR)){
        nprologueY <- nyear - length(cmip_dwn$YEAR)
        prologueY <- (cmip_dwn$YEAR[1]-nprologueY):(cmip_dwn$YEAR[1]-1)
        yrs <- c(prologueY, cmip_dwn$YEAR)
      # If no additional years needed then just take them from the years
      # time series.
      }else{
        yrs <- rev(rev(cmip_dwn$YEAR)[1:nyear])
      }
      omval$YEAR <- yrs
    }
    
    
    # Assessment model diagnostics ... -1 gives 1 NA. Will change when I get
    # around to reporting all years for all metrics.
    omval$relE_qI[r,m,] <- relE_qI
    omval$relE_qC[r,m,] <- relE_qC
    omval$relE_selCs0[r,m,] <- relE_selCs0
    omval$relE_selCs1[r,m,] <- relE_selCs1
    omval$relE_ipop_mean[r,m,] <- relE_ipop_mean
    omval$relE_ipop_dev[r,m,] <- relE_ipop_dev
    omval$relE_R_dev[r,m,] <- relE_R_dev
    omval$relE_SSB[r,m,] <- relE_SSB
    omval$relE_N[r,m,] <- relE_N
    omval$relE_IN[r,m,] <- relE_IN
    omval$relE_R[r,m,] <- relE_R #AEW
    omval$relE_F[r,m,] <- relE_F #AEW
    omval$conv_rate[r,m,]<-conv_rate #MDM
    omval$Mohns_Rho_SSB[r,m,]<-Mohns_Rho_SSB 
    omval$Mohns_Rho_N[r,m,]<-Mohns_Rho_N#MDM
    omval$Mohns_Rho_F[r,m,]<-Mohns_Rho_F#MDM
    omval$Mohns_Rho_R[r,m,]<-Mohns_Rho_R#MDM
    omval$mincatchcon[r,m,]<-mincatchcon
    
    if(y>=fmyearIdx){
      omval$SSBest[y,1:length(stock$res$SSB)]<-stock$res$SSB
      omval$Fest[y,1:length(stock$res$SSB)]<-stock$res$F.report
      omval$Catchest[y,1:length(stock$res$SSB)]<-stock$res$catch.pred
      omval$Rest[y,1:length(stock$res$SSB)]<-stock$res$N.age[,1]
    }
    
    if (y == nyear){
    omval$relTermE_SSB[r,m,] <- relTermE_SSB #MDM
    omval$relTermE_CW[r,m,] <- relTermE_CW #MDM
    omval$relTermE_CW[r,m,] <- relTermE_CW #MDM
    omval$relTermE_IN[r,m,] <- relTermE_IN #MDM
    omval$relTermE_qI[r,m,] <- relTermE_qI #MDM
    omval$relTermE_R[r,m,] <- relTermE_R #MDM
    omval$relTermE_F[r,m,] <- relTermE_F #MDM
    }
    #Econ specific outputs. Not put until management starts in fmyearIdx
    if(mproc$ImplementationClass[m]=="Economic"){
      if(y >= fmyearIdx){
    omval$Gini_stock_within_season_BKS[r,m,y]<-Gini_stock_within_season_BKS[y] #Gini coefficient over the days of the fishing year
    omval$econCW[r,m,y]<-econCW[y] #"Economic" total catch in metric tons  
    omval$avgprice_per_lb[r,m,y]<-avgprice_per_lb[y] #"Economic" total catch in metric tons  
    omval$modeled_fleet_removals_mt[r,m,y]<-modeled_fleet_removals_mt[y] #"Economic" total catch in metric tons  
    
      }
    }    
  })

  return(out)
  
}

