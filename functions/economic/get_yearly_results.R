# A function to pick the yearly results from omvalGlobal and store them in a nice data frame. 
# Note, omvalGlobal is hard coded here, but it would be better to pick the results from flLst

# metric is the name of yearly results from an element of omvalGlobal (like SSB, F_full).
# Note, d3 is the index number of the vector yrs, it is not the year of the simulation. 

get_yearly_results <- function(metric,stocknum){
  temp<- omvalGlobal[[stocknum]][[metric]]
  
  d1<-1:dim(temp)[1]
  d2<-1:dim(temp)[2]
  d3<-1:dim(temp)[3]
  
  temp<-as_tibble(cbind(expand.grid(d1,d2,d3), value = as.vector(temp)))
  temp<-temp %>%
    dplyr::rename(replicate=Var1,
                  mproc=Var2,
                  year=Var3)  %>%
    dplyr::mutate(stock=names(omvalGlobal[stocknum]),
                  metric={{metric}})
}
