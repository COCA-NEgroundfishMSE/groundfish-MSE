# Verifying economic results at monthly level 


verify_econ_results= function (monthly_summary, r=100){
#Check for  years 2010:2015
modeled_years = unique(monthly_summary$year, by = c("replicate","month", "model"))
years = c(2010:2015)
missing_y = paste(as.character(setdiff(years, modeled_years)),collapse=", ")

yr = ifelse(length(modeled_years)!=6, paste("Missing years:", missing_y), paste("Results contain all modeled years, 2010:2015."))

#Check for replicates 
r = as.numeric(1:r)
modeled_replicates = unique(monthly_summary$replicate, by = c("year","month", "model"))

reps = ifelse(identical(modeled_replicates, r) == FALSE, paste("Results only contain", length(modeled_replicates), "replicate(s)."), 
       paste("All 1:", length(r), "replicates found."))

#Check for all models 
m =  c("counterfactual_pre_coefsnc1", "counterfactual_pre_coefsnc2", "counterfactual_pre_coefs1",   "counterfactual_pre_coefs2", 
       "validation_pre_coefsnc1", "validation_pre_coefsnc2", "validation_pre_coefs1",   "validation_pre_coefs2")
modeled_m = unique(monthly_summary$model, by = c("year","month", "replicate"))
missing_m = paste(as.character(setdiff(m, modeled_m)),collapse=", ")


mod = ifelse(identical(modeled_m, m) == FALSE, paste("Results only contain", length(modeled_m), "models(s). Missing", missing_m),
       paste("All", length(m), "models found."))

#Check for months 
months = as.numeric(1:12)
modeled_months = unique(monthly_summary$month, by = c("year","replicate", "model"))

mon = ifelse (identical(modeled_months, months)==FALSE, paste("Results only contain", length(modeled_months), "months"),
        paste("Results contain all months, 1:", length(modeled_months)))

print(yr)
print(reps)
print(mod)
print(mon)
}
