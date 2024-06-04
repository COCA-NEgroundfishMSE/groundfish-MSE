
# Function to subset the data based on a column and set of criteria and then compute a gini
## Pass in a dataset, the name of a column that contains the values, a filter variable
## The  value of the filter variable is assumed to be a character (string) 
## call get_gini()

get_gini_subset=function(dataset, y, filter_var, filter_value){
  filter_var2<-as.name(filter_var)
  ds2<-dataset %>%
    dplyr::filter(!!filter_var2==!!filter_value)
  Gini<-get_gini(ds2,y)
  return(Gini)
}



## Data setup and example
#  library(dplyr)
#  library(readr)
#  library(tidyr)
#  id=c(1,2,3,4,5,1,1,1,2,2,2)
#  id2=c("A","B","C","D","G","A","A","C","B","B","C")
#  income2=c(11,12,13,14,15,17,18,19,20,21,22)
#  income=c(1,2,3,4,5,6,7,9,10,11,12)
#  ref2<-c(10,10,10,10,10,10,10,10,10,10,10)
#  test_data<-as_tibble(cbind(id2, id,income,income2, ref2)) %>%
#    mutate_at(c(2:5), as.numeric)
#  
#  rm(list=c("income", "income2", "id","ref2", "id2"))
#  
# 
# get_gini_subset(test_data,y="income",filter_var="id2",filter_value="A")
# get_gini_subset(test_data,y="income",filter_var="id2",filter_value="B")
# get_gini_subset(test_data,y="income",filter_var="id2",filter_value="C")
# 
# ids2<-c("A","B", "C")
#  
# test<- lapply(ids2, get_gini_subset, dataset=test_data, y="income", filter_var="id2")
# names(test)<-ids2
# test
