# Preliminary data processing for the MSE model  
# MSE model is "post-as-post" uses
#       Post- production, post multipliers, post prices
#       Post-choice coefficients, 
#       slightly adjusted data. 
# 
here::i_am("preprocessing/economic/pre_process_MSE_whitefish_up_price_sims.R")


library(readstata13)
library(tidyr)
library(dplyr)
library(data.table)
library(here)

# Setting up the data.
# Before you do anything, you put all your "data" files into the 
# /data/data_raw/econ 
 
    # main data file: data_for_simulations_mse.dta, data_for_simulations_POSTasPOST.dta, data_for_simulations_POSTasPRE.dta
    # multipliers.dta (multipliers)
    # production coefficients:  production_regs_actual_post_for_R.txt,production_regs_actual_pre_for_R.txt
    # Logit coefficients: preCSasclogit2.ster,postCSasclogit2.ster


# file paths for the raw and final directories
# windows is kind of stupid, so you'll have to deal with it in some way.
rawpath <- here("data","data_raw","econ")
savepath <- here("data","data_processed","econ")
# Just a guess on your paths.  


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


#the MSE  dataset always uses post production.
production_vars<- production_vars_post
# ############## End Independent variables in the Production equation ##########################
models <-c("post_coefsnc2")

####################Locations of files. 


# MSE uses post-targeting coefficients
trawl_targeting_coef_source<-c("asclogit_trawl_post_coefsnc2.txt", "asclogit_trawl_post_coefs.txt")
gillnet_targeting_coef_source<-c("asclogit_gillnet_post_coefsnc2.txt", "asclogit_gillnet_post_coefs.txt")

target_coef_outfile<-c("targeting_coefs_post_coefsnc2.Rds", "targeting_coefs_post_coefs.Rds")
#MSE uses post-production coefficients
production_coef_in<-"production_regs_actual_post_forR.txt"
production_outfile<-"production_coefs_post.Rds"


# bits for input_price_import.R 
file_prefix<-"MSE_"
input_price_loc<-paste0("MSE_post_input_price_series.dta")

input_preoutfile<-paste0(file_prefix,"pre_input_prices.Rds")
input_postoutfile<-paste0(file_prefix,"post_input_prices.Rds")
input_working<-input_postoutfile

# bits for multiplier_import.R 
multip_location<-"reshape_multipliers.dta"
multi_postoutfile<-paste0(file_prefix,"post_multipliers.Rds")
multi_preoutfile<-paste0(file_prefix,"pre_multipliers.Rds")
multiplier_working<-multi_postoutfile

# bits for output_price_import.R 
output_price_loc<-paste0(file_prefix,"adj_whitefish_up_price_series.dta")
output_preoutfile<-paste0(file_prefix,"adj_pre_whitefish_up_price_series.Rds")
output_postoutfile<-paste0(file_prefix,"adj_post_whitefish_up_price_series.Rds")
output_working<-output_postoutfile

# bits for day limits dataset 
day_limits <- "trip_limits_forsim.dta"

####################END Locations of files. You shouldn't have to change these unless you're adding new datasets (like a pre-as-pre or pre-as-pre), new coefficients, new multipliers, etc) 








####prefix  (see datafile_split_prefix in wrapper.do)
yrstub<-"econ_data"
# yearly_savename<-c("full_targeting_coefsnc2", "full_targeting_coefs")
yearly_savename<-c("MSE_whitefishP_up")


source(here("preprocessing","economic","targeting_coeff_import.R"))
source(here("preprocessing","economic","production_coefs.R"))
#output prices
 
source(here("preprocessing","economic","output_price_import.R"))
source(here("preprocessing","economic","multiplier_import.R"))

#input prices
source(here("preprocessing","economic","input_price_import.R"))

# Quota price 
source(here("preprocessing","economic","quota_price_coefs.R"))


# This takes quite a while 
production_coefs<-production_outfile
production_coefs<-readRDS(file.path(savepath, production_coefs))
production_coefs[, post:=NULL]

source(here("preprocessing","economic","import_day_limits_validation.R"))
source(here("preprocessing","economic","targeting_data_import.R"))



