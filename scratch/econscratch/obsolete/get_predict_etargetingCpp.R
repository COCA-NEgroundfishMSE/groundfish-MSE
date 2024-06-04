# A function to do predictions for the economic targeting model. 
#
# tds: Combined dataset of targeting data and asclogit coefficients 
# I need to :
# A. compute xb. 
# B. exponentiate
# C. Compute the total, by id
# D. Compute prob = exp(xb)/total exp(xb)

#.Unsure if the NA are handled properly.  Also unsure if the "No Fish" option will be properly constructed (Troubleshoot: if the utility function equation is fixed AND I get a matrix of NAs, then the utility for the no-fish option isn't properly being constructed. I'm pretty sure that this gets set =0 (so exp(0)=1). There are no coefficients for no fish model.
# returns a data.table with extra columns in it (xb, expu, totexpu, and prhat).

get_predict_etargetingCpp <- function(tds){
  # pull the betas into matrix, pull the data variables into a matrix and mulitiply them.  
  
  #These need to be changed
  
  
  datavars=c("exp_rev_total","das_charge","fuelprice_distance","mean_wind","mean_wind_noreast","permitted","lapermit","distance","wkly_crew_wage","len","fuelprice","fuelprice_len","start_of_season","partial_closure","constant")
  
  betavars=paste0("beta_",datavars)

  
X<-as.matrix(tds[, ..datavars])

B<-as.matrix(tds[, ..betavars])

tds$xb<-Sugar_rowSums(X*B)
tds$expu<-exp(tds$xb)

tds[, totexpu := sum(expu), by = id]

tds$prhat<- tds$expu/tds$totexpu
  
  return(tds)
}

