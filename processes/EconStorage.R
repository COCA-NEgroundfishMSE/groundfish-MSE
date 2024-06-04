# Results folders for economic models. Create them if necessary
dir.create(file.path(ResultDirectory,"econ", "raw"), showWarnings = FALSE, recursive=TRUE)
dir.create(file.path(ResultDirectory,"econ", "sim"), showWarnings = FALSE, recursive=TRUE)
dir.create(file.path(ResultDirectory,"econ", "fig"), showWarnings = FALSE, recursive=TRUE)

run_num<-1

econ_results_location<-file.path(ResultDirectory,"econ","raw",run_num)

while(dir.exists(econ_results_location)==TRUE){
  run_num<-run_num+1
  econ_results_location<-file.path(ResultDirectory,"econ","raw",run_num)
}

dir.create(file.path(econ_results_location), showWarnings = FALSE, recursive=TRUE)
