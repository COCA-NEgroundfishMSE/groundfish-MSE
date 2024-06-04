
# Function to compute a shannon index
## Pass in a dataset and the name of a column, in quotation marks
## sort in non-decreasing order 
## HHI = \sum_i=1^n share_i^2

get_shannon=function(dataset, y){
  y2<-as.name(y)
  invar<-dataset %>%
    mutate(total=sum(!!y2)) %>%
    mutate(share=!!y2/total) %>%
    summarise(shannon=-1*sum(share*log(share)) )
  return(invar$shannon)
}


# 
# #Data setup and example
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
# get_HHI(dataset=test_data,y="income")
# # HHI==0.2444
# get_shannon(dataset=test_data,y="income")
# # Shannon==1.48975