# This stores the Simulation level a place. These are performance metrics that are useful for a multispecies model, but are not necessarily economic.
# Borrowed from get_fillRepArrays, but simpler because my objects are in the global environment instead of elements of stock

get_fillRepArraysSimLevel <- function(simulation_container){
  simulation_container$HHI_fleet[r,m,y]<-HHI
  simulation_container$Shannon_fleet[r,m,y]<-shannon
  simulation_container$Theil_managed_CtoB[r,m,y]<-Theil_managed_CtoB
  simulation_container$Theil_managed_Relative_C[r,m,y]<-Theil_managed_Relative_C

  
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
    simulation_container$YEAR <- yrs
  }
  
  return(simulation_container)
  
}


