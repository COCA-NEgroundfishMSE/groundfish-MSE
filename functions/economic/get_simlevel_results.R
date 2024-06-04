# A function to pick the simulation results from omvalGlobal and store them in a nice data frame. 
# metric is the name of Simulation-Level results from an element of omvalGlobal (like 
# "ie_F_hat" or "iebias_hat"

# Note, omvalGlobal is hard coded here, but it would be better to pick the results from flLst

get_simlevel_results <- function(metric, stocknum){
  temp<- omvalGlobal[[stocknum]][[metric]]
  d1<-1:dim(temp)[1]
  d2<-1:dim(temp)[2]
  
  temp<-as_tibble(cbind(expand.grid(d1,  d2), value = as.vector(temp)))
  temp<-temp %>%
    dplyr::rename(replicate=Var1,
                  mproc=Var2) %>%
    dplyr::mutate(stock=names(omvalGlobal[stocknum]),
                  metric={{metric}})
}
