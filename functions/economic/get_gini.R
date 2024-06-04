
# Function to compute the Gini Coefficient
## Pass in a dataset and the name of a column, in quotation marks
## sort in non-decreasing order 
## G = \frac{2\sum i*y}{n \sum y} - \frac{n+1}{n}
## This could be used to compute a Gini to measure inequality of vessel level outcomes, perhaps at the stock level.
## This could be used to compute a Gini to measure inequality of catch across stocks for the fleet.
get_gini=function(dataset, y){
  y2<-as.name(y)
  nobs<-nrow(dataset)
  invar<-dataset %>%
    arrange(!!y2) %>%
    mutate(rank=row_number()) %>%
    mutate(addend=rank*!!y2) %>%
    summarise(numer=sum(addend),
              denom=sum(!!y2)) %>%
    mutate(gini=2*numer/(nobs*denom)-(nobs+1)/nobs)
  return(invar$gini)
}



## Data setup and example
# library(dplyr)
# library(readr)
# library(tidyr)
# id=c(1,2,3,4,5)
# income2=c(11,12,13,14,15)
# income=c(1,2,3,4,5)
# ref2<-c(10,10,10,10,10)
# test_data<-as_tibble(cbind(id, income,income2, ref2))
# rm(income)
# rm(income2)
# yvars<-list("income","income2")
# get_gini(test_data, "income")
# get_gini(test_data,"income2")
# lapply(yvars, get_gini, dataset=test_data)
