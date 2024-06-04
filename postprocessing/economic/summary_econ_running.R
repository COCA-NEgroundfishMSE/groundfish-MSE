#Summarizing econ results at a monthly resolution.

# This is pretty janky. But if you don't summarize as you go along, you'll end up with a massive dataset.  
# Instead of reading everything in, then summarizing, you'll read in a dataset, summarize it and store it in a list. Then concatenate all the lists together.
# The result csv's may or may not contain an entire replicate; but they will contain entire fishing years.
library(data.table)

# Naming outputs 

remote_location <- "/net/ftp/pub/dropoff/mlee/anna/summary"
#Uncomment one of these stub names

#stub<-"counterfactual_closeownA"
#stub<-"validationA"
stub<-"counterfactual_closemult"

econ_out_csv<-paste0("monthly_summary_",stub,".csv")
stock_status_out_csv<-paste0("stock_status_",stub,".csv")
pr_hat_out_csv<-paste0("pr_hat_",stub,".csv")


####################################################
#where are the result csvs?
#selects most recent file path in groundfish_MSE folder that starts with "results_" 
# Option 1: Select the most recent folder automatically
# file_path = file.info(list.files(path=".",pattern="^results_*",include.dirs=TRUE,full.names = T,recursive=TRUE))
# file_path= rownames(file_path)[which.max(file_path$mtime)]
# Option 2: Manually enter the name of the results folder.  The "." is relative to the root of the project.
file_path="./results_2021-04-21-14-40-06"

#selects csvs that start with a particular pattern 
select_pat<- "econ_2020"
file_names = list.files(path=file.path(file_path, "econ","raw"), pattern =select_pat, full.names = TRUE)

# Cut out or stop options. some of the Simulations ran partially and therefore only have partial data.  
# We need to to keep 
maxrep<-100






# need to write code for lines 32-73 that works on the pr_hat data
#binding into a data.table
simulations<-list()
file_nums<-length(file_names)
for(file in 1:file_nums){

sim<-fread(file_names[file], stringsAsFactors = FALSE)
sim[, trips := 1]

setnames(sim, old="r", new="replicate")
setnames(sim, old="m", new="model")

#selecting one replicate for daily resolution 
#daily_summary = sim[sim$replicate==1]
#daily_summary [ ,c("id","hullnum", "y") := NULL]
#daily_summary = daily_summary [, lapply(.SD, sum, na.rm=TRUE), by=list(year, doffy, spstock2, gearcat, replicate, model)]

#write.csv(daily_summary, paste0(file_path, "daily_summary.csv"))

#monthly resolution data 

#generate date from doffy and extract month only 
sim[, month := month(as.Date(doffy, origin=paste0(year, "-04-30"))), by=year]
#start fishing year May = 1 
sim[, month := ifelse(month < 5, month+8, month-4)]
sim[ ,c("id","hullnum", "doffy", "y") := NULL]

monthly_summary = sim[, lapply(.SD, sum, na.rm=TRUE), by=list(year, month, spstock2, gearcat, replicate, model)]

simulations[[file]]<-monthly_summary
}


monthly_summary <- rbindlist(simulations,use.names=TRUE,fill=TRUE) 

table(monthly_summary$replicate)
monthly_summary <- monthly_summary[replicate<=maxrep]

#Verifying econ results before saving
#source("postprocessing/economic/verify_econ_result.R")
#verify_econ_results(monthly_summary = monthly_summary)



write.csv(monthly_summary, file.path(file_path, econ_out_csv))





#read in stock status




file_names = list.files(path=file.path(file_path, "econ","raw"), pattern = "econ_stock_status", full.names = TRUE)


#binding into a data.table
stock_status<-list()


#don't read the last file name
file_nums<-length(file_names)

for(file in 1:file_nums){
  
  
  sim<-fread(file_names[file], stringsAsFactors = FALSE)

  setnames(sim, old="r", new="replicate")
 # setnames(sim, old="m", new="model")
  
  stock_status[[file]]<-sim
}



stock_status <- rbindlist(stock_status,use.names=TRUE,fill=TRUE) 
stock_status <- stock_status[replicate<=maxrep]

stock_status[,c("bio_model","SSB","mults_allocated","sectorACL"):=NULL]
# 1 row per  per year, spstock2, replicate, model,
# Either the last day of the year OR the first day where the stock_area was closed or the acl was reached

stock_status<-stock_status[(underACL==FALSE | doffy==365 | stockarea_open==FALSE)]

stock_status<-stock_status[, head(.SD, 1), by = c("year","spstock2","replicate","m")]

write.csv(stock_status, file.path(file_path, stock_status_out_csv))










#read in prhats
# 
# 
# 
# 
# file_names = list.files(path=file.path(file_path, "econ","raw"), pattern = "prhat_", full.names = TRUE)
# 
# 
# #binding into a data.table
# prhat<-list()
# 
# 
# #don't read the last file name
# file_nums<-length(file_names)
# 
# for(file in 1:file_nums){
#   
#   
#   sim<-fread(file_names[file], stringsAsFactors = FALSE)
#   
#   setnames(sim, old="r", new="replicate")
#   setnames(sim, old="m", new="model")
#   
#   
#   
#   
#   
#   #generate date from doffy and extract month only 
#   sim[, month := month(as.Date(doffy, origin=paste0(year, "-04-30"))), by=year]
#   #start fishing year May = 1 
#   sim[, month := ifelse(month < 5, month+8, month-4)]
#   sim[ ,c("doffy", "y") := NULL]
#   
#   sim = sim[, lapply(.SD, sum, na.rm=TRUE), by=list(year, month, replicate, model,gearcat,hullnum)]
#   
#   prhat[[file]]<-sim
# }
# 
# 
# 
# 
# prhat<-rbindlist(prhat,use.names=TRUE,fill=TRUE) 
# 
# prhat <- prhat[replicate<=cutout]
# 
# write.csv(prhat, file.path(file_path, pr_hat_out_csv))
# 


# Zip up the outputs and save them somewhere.
# zipping straight to the ftp doesn't work on my workstation. Instead, zip right into your file path and then copy it over

# uncomment this on the mlee_workstation
#remote_location<-file_path

zipcommand <-paste0("zip ",remote_location,"/",stub,"_summary.zip ", file_path,"/*.csv" )
sha1command <-paste0("sha1sum ",remote_location,"/",stub,"_summary.zip > ", remote_location,"/",stub,"_summary.zip.sha1")

system(zipcommand)
system(sha1command)


fullzipcommand <-paste0("zip -r ",remote_location,"/",stub,"_full.zip ", file_path,"/econ/raw/econ_*.csv" )
fullsha1command <-paste0("sha1sum ",remote_location,"/",stub,"_full.zip > ", remote_location,"/",stub,"_full.zip.sha1")

system(fullzipcommand)
system(fullsha1command)
