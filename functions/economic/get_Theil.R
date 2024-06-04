# Function to compute a Theil Index
## Pass in the name of the dataset and the variable. 
## The variable should have quotation marks around it.
## T = 1/N* \sum y/pi * ln(y/pi)
## when y=0, I drop the observation for the summation(it's NaN) but include it for the computation of nobs.


get_Theil=function(dataset, y){
  y2<-as.name(y)
  nobs<-nrow(dataset)
  working<-dataset  %>%
    mutate(meany=mean(!!y2)) %>%
  dplyr::filter(!!y2>0) %>%
    mutate(proportionality_factor=!!y2/meany) %>%
    summarise(Thiel=sum(proportionality_factor*log(proportionality_factor)/nobs))
  return(working$Thiel)
}




# # Data setup and example
# library(dplyr)
# id=c(1,2,3,4,5)
# income2=c(11,12,13,14,15)
# income=c(1,2,3,4,5)
# ref2<-c(10,10,10,10,10)
# test_data<-as_tibble(cbind(id, income,income2, ref2))
# rm(income)
# rm(income2)
# 
# 
# T1<-get_Theil(test_data, "income")
# T2<-get_Theil(test_data, "income2")
# 
# yvars<-list("income","income2")
# 
# T<-lapply(yvars, FUN=get_Theil, dataset=test_data) 
# 
# T1
# T2
# T
