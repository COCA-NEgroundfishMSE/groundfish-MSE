# Preliminary data processing for the model validation.  
# Model validation "post-as-post" uses
#       Post- production, post multipliers, post prices
#       pre-choice coefficients, 
#       slightly adjusted data. 
# 
rm(list=ls())
if(!require(readstata13)) {  
    install.packages("readstata13")
    require(readstata13)}
if(!require(tidyr)) {  
    install.packages("tidyr")
    require(tidyr)}
if(!require(dplyr)) {  
    install.packages("dplyr")
    require(dplyr)}
if(!require(data.table)) {  
    install.packages("data.table")
    require(data.table)}

# Setting up the data.
# Before you do anything, you put all your "data" files into the 
# /data/data_raw/econ folder
 
    # main data file: data_for_simulations_mse.dta, data_for_simulations_POSTasPOST.dta, data_for_simulations_POSTasPRE.dta
    # multipliers.dta (multipliers)
    # production coefficients:  production_regs_actual_post_for_R.txt,production_regs_actual_pre_for_R.txt
    # Logit coefficients: preCSasclogit2.ster,postCSasclogit2.ster


# file paths for the raw and final directories
# windows is kind of stupid, so you'll have to deal with it in some way.
rawpath <- './data/data_raw/econ'
savepath <- './data/data_processed/econ'
# Just a guess on your paths.  
#rawpath <- 'C:/Users/abirken/Documents/GitHub/groundfish-MSE/data/data_raw/econ'
#savepath <- 'C:/Users/abirken/Documents/GitHub/groundfish-MSE/data/data_processed/econ'



###########################Make sure you have the correct set of RHS variables.
# Model 2 has a slightly different exp_rev_total variable.

spstock_equation_prenc1=c("exp_rev_total", "fuelprice_distance", "distance", "mean_wind", "mean_wind_noreast", "permitted", "lapermit", "choice_prev_fish", "partial_closure", "start_of_season")
choice_equation_prenc1=c("das_price_mean", "das_price_mean_len","wkly_crew_wage", "len", "fuelprice", "fuelprice_len")

spstock_equation_pre1<-c(spstock_equation_prenc1,"constant")
choice_equation_pre1<-choice_equation_prenc1


spstock_equation_prenc2<-c("exp_rev_total_das", "fuelprice_distance", "distance", "mean_wind", "mean_wind_noreast", "permitted", "lapermit", "choice_prev_fish", "partial_closure", "start_of_season")
choice_equation_prenc2<-c("wkly_crew_wage", "len", "fuelprice", "fuelprice_len")

spstock_equation_pre2<-c(spstock_equation_prenc2,"constant")
choice_equation_pre2<-choice_equation_prenc2


#These are mostly placeholders
spstock_equation_postnc1<-spstock_equation_prenc1
choice_equation_postnc1<-choice_equation_prenc1

spstock_equation_post1<-spstock_equation_pre1
choice_equation_post1<-choice_equation_pre1

spstock_equation_postnc2<-spstock_equation_prenc2
choice_equation_postnc2<-choice_equation_prenc2

spstock_equation_post2<-spstock_equation_pre2
choice_equation_post2<-choice_equation_pre2
############## End Independent variables in the targeting equation ##########################



# 
# ##############Independent variables in the Production equation ##########################
# ### If there are different the equations, you can set there up here, then use their suffix in the mproc file to use these new targeting equations
# ### example, using ProdEqn=tiny in the mproc file and uncommenting the next  line will be regression with 2 RHS variables and no constant.
# # production_vars_tiny=c("log_crew","log_trip_days")
# 
 production_vars_pre=c("log_crew","log_trip_days","primary","secondary", "log_trawl_survey_weight","constant")
 production_vars_post=c("log_crew","log_trip_days","primary","secondary", "log_trawl_survey_weight","log_sector_acl", "constant")
 
 #the validation dataset always uses post production.
 production_vars<- production_vars_post
# ############## End Independent variables in the Production equation ##########################
# 
# 
# 
# 
# #spstock_equation2=c("exp_rev_total_das", "fuelprice_distance", "distance", "mean_wind", "mean_wind_noreast", "permitted", "lapermit", "choice_prev_fish", "partial_closure", "start_of_season")
# 
# choice_equation=c("wkly_crew_wage", "len", "fuelprice", "fuelprice_len")
# 
# targeting_vars=c(spstock_equation, choice_equation)
# 
# production_vars=c("log_crew","log_trip_days","log_trawl_survey_weight","log_sector_acl","primary", "secondary","constant")

####################Locations of files. 
# Validation uses pre-targeting coefficients
models = paste0("post_", c("coefsnc2"))
trawl_targeting_coef_source<- paste0("asclogit_trawl_", models ,".txt")
gillnet_targeting_coef_source<- paste0("asclogit_gillnet_", models ,".txt")
target_coef_outfile<-paste0("targeting_coefs_", models, ".Rds")


# bits for input_price_import.R 
file_suffix<-"_valid"

input_price_loc<-paste0("input_price_series",file_suffix,".dta")
input_preoutfile<-paste0("input_prices_pre",file_suffix,".Rds")
input_postoutfile<-paste0("input_prices_post",file_suffix,".Rds")
input_working<-input_postoutfile

# bits for multiplier_import.R 
multip_location<-"reshape_multipliers.dta"
multi_postoutfile<-paste0("sim_multipliers_post",file_suffix,".Rds")
multi_preoutfile<-paste0("sim_multipliers_pre",file_suffix,".Rds")
multiplier_working<-multi_postoutfile

# bits for output_price_import.R 
output_price_loc<-paste0("output_price_series",file_suffix,".dta")
output_preoutfile<-paste0("output_prices_pre",file_suffix,".Rds")
output_postoutfile<-paste0("output_prices_post",file_suffix,".Rds")
output_working<-output_postoutfile

# bits for day limits dataset 
day_limits <- "trip_limits_forsim.dta"

####################END Locations of files. You shouldn't have to change these unless you're adding new datasets (like a pre-as-pre or pre-as-pre), new coefficients, new multipliers, etc) 

####prefix  (see datafile_split_prefix in wrapper.do)
yrstub<-"POSTasPOST"

yearly_savename<-paste0("validation_", models) 

source('preprocessing/economic/targeting_coeff_import.R')


