#Summarizing resutls at a monthly and daily resolution 

library(data.table)

#selects most recent file path in groundfish_MSE folder, which should be resuls_2020-... if the runsim_Econonly.R has just been run 
source('processes/identifyResultDirectory.R')

dir.create(file.path(ResultDirectory,"summary"))
#if that does not work then the file path needs to be copied in 
#file_path = "./results_2020-07-31-19-06-26/"

#selects just the econ_2023 datasets
file_names = list.files(path=file.path(ResultDirectory,"econ", "raw"), 
                        pattern = "econ_2023", full.names = TRUE)

#binding into a data.table
simulations = (lapply(file_names, fread, stringsAsFactors = FALSE))
sim = rbindlist(simulations)

#sim[, trips := 1]

setnames(sim, old="r", new="nreps")
setnames(sim, old="m", new="model")


sim <-sim %>%
  dplyr::filter(year==2020) %>%
  group_by(model, nreps, year, doffy,hullnum) %>%
  dplyr::arrange(model, nreps, year, doffy,hullnum)


#selecting one replicate for daily resolution 
daily_summary = sim[sim$nreps==1]
daily_summary [ ,c("id","hullnum", "y") := NULL]
daily_summary = daily_summary [, lapply(.SD, sum, na.rm=TRUE), by=list(year, doffy, spstock2, gearcat, nreps, model)]

write.csv(daily_summary, file.path(ResultDirectory,"summary","daily_summary.csv"))


setcolorder(daily_summary, c("year", "doffy","gearcat",  "spstock2", "trips","c_redfish", "c_codGOM","c_whitehake",
                             "r_redfish", "r_codGOM", "r_whitehake"))




#monthly resolution data 

#generate date from doffy and extract month only 
sim[, month := month(as.Date(doffy, origin=paste0(year, "-04-30"))), by=year]
#start fishing year May = 1 
sim[, month := ifelse(month < 5, month+8, month-4)]
sim[ ,c("id","hullnum", "doffy", "y") := NULL]

monthly_summary = sim[, lapply(.SD, sum, na.rm=TRUE), by=list(year, month, spstock2, gearcat, nreps, model)]

write.csv(monthly_summary, file.path(ResultDirectory,"summary","monthly_summary.csv"))




