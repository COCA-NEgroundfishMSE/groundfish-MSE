# This stores the Economic results that are at the simulation level in a place.
# Borrowed from get_fillRepArrays, but simpler because my objects are in the global environment
# This is the function that should be used when we are storing performance metrics that are only constructed in an Economic model run.

get_fillRepArraysEcon <- function(simulation_container){
  simulation_container$Gini_fleet[r,m,y]<-Gini_fleet
  simulation_container$Gini_fleet_bioecon_stocks[r,m,y]<-Gini_fleet_bioecon_stocks
  simulation_container$total_fleet_rev[r,m,y]<-total_fleet_rev
  simulation_container$total_fleet_groundfish_rev[r,m,y]<-total_fleet_groundfish_rev
  simulation_container$total_fleet_modeled_rev[r,m,y]<-total_fleet_modeled_rev
  
  return(simulation_container)
  
}


