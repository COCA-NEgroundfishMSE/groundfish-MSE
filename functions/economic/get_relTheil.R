# Function to compute a Theil Index
## Pass in the name of the dataset, the variable, and the reference distribution.
## The variable and the reference distribution should have quotation marks around it.
## The 'mean' is common, if you want to do this, you have to create the mean separately and pass that in. 
## To compute an "absolute" Theil, just pass in a column of "1" for the reference
## T = 1/N* \sum y/pi * ln(y/pi)
## when y=0, I drop the observation (it's NaN) but include it for the computation of nobs.

## This is less useful to lapply on, because I don't know how to vary up the reference distribution.


get_relTheil=function(dataset, y, pi){
  y2<-as.name(y)
  pi2<-as.name(pi)
  nobs<-nrow(dataset)
  working<-dataset  %>%
    dplyr::filter(!!y2>0) %>%
    mutate(proportionality_factor=!!y2/!!pi2) %>%
    summarise(Thiel=sum(proportionality_factor*log(proportionality_factor)/nobs))
  return(working$Thiel)
}




# Data setup
# id=c(1,2,3,4,5)
# income2=c(11,12,13,14,15)
# income=c(1,2,3,4,5)
# ref2<-c(10,10,10,10,10)
# test_data<-as_tibble(cbind(id, income,income2, ref2))
# rm(income)
# rm(income2)
# 
# 
# T1<-get_relTheil(test_data, "income", "ref2")
# T2<-get_relTheil(test_data, "income2", "ref2")
# 
# yvars<-list("income","income2")
# 
# T<-lapply(yvars, FUN=get_relTheil, dataset=test_data, pi="ref2")
# 
# T1
# T2
# T
