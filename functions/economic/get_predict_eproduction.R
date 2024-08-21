

# A function to do predictions for the production model. 
#
# prod_ds: Combined dataset of production data and coefficients recovered 
# 	from a log-log regression.
# logh=q+XB, where X is q, log crew, log trip days, log cumulative harvest, primary, secondary, and dummies for month and fishing year.
# Returns a data.table with an extra column in it.

get_predict_eproduction <- function(prod_ds){
  # crew, trip days, trawl survey, 
  fyvars<-grep("^fy",colnames(prod_ds) , value=TRUE)
  monthvars<-grep("^month",colnames(prod_ds) , value=TRUE)
  
  datavars=c(production_vars,fyvars,monthvars)
  alphavars=paste0("alpha_",datavars)
  
  
    Z<-as.matrix(prod_ds[, ..datavars])
  A<-as.matrix(prod_ds[,..alphavars])
  
  prod_ds[, harvest_sim:=rowSums(Z*A)+q]
  
  #prod_ds$harvest_sim<-rowSums(Z*A)
  #prod_ds[, harvest_sim:=harvest_sim+q]
  #prod_ds$harvest_sim=prod_ds$harvest_sim+prod_ds$q
  
  #production
  # bad way to smear
  #prod_ds$harvest_sim<- exp(prod_ds$harvest_sim + fx)*exp((prod_ds$rmse^2)/2)
  
  #good way to smear. Ad-hoc adjustment so emean is no larger than 3.
  prod_ds[, harvest_sim:=(exp(harvest_sim))*emean]
}

