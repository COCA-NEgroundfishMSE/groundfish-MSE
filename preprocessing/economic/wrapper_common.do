version 15.1

/* Run this file to load/prep the economic data that is common for all scenarios.
This set of data processing is the same for all of the different scenarios.
So we only need to run this once. And run this before you run the other wrappers

*/
global projectdir $MSEprojdir 
*global projectdir "/home/mlee/Documents/projects/GroundfishCOCA/groundfish-MSE"
*global projectdir "C:/Users/abirken/Documents/GitHub/groundfish-MSE"

global inputdir "$projectdir/data/data_raw/econ"
global outdir "$projectdir/data/data_processed/econ"
global codedir "$projectdir/preprocessing/economic"
global bio_data "$projectdir/data/data_processed/catchHistory"




/* filenames for sters  and outputs*/
global post_input_ster "postCSasclogitnc2.ster"


global post_gillnet_out "asclogit_gillnet_post_coefs.txt"
global post_trawl_out "asclogit_trawl_post_coefs.txt"


global pre_input_ster "preCSasclogitnc2.ster"
global pre_gillnet_out "asclogit_gillnet_pre_coefs.txt"
global pre_trawl_out "asclogit_trawl_pre_coefs.txt"



/*construct prices, reshape multipliers, and bring both into the targeting dataset */
global catch_hist_file "catchHist.csv"

/*name of multiplier file*/

global multiplier_file "multipliers.dta"
global multiplier_out "reshape_multipliers.dta"

global datafilename "data_for_simulations_mse.dta"



do "$codedir/asclogit_coef_export.do"
do "$codedir/stocks_in_model.do"

do "$codedir/recode_catch_limits.do"
do "$codedir/multiplier_prep.do"


/* read in the quota price coefficients*/


do "$codedir/quota_price_coef_export.do"
/* get rhs data needed for quota price predictions */
do "$codedir/quota_price_data_export.do"




do "$codedir/readin_older_catchHist.do"
do "$codedir/compute_catch_limit_deviations.do"

