version 15.1

/* Run this file to load/prep the economic data that is common for all scenarios.
This set of data processing is the same for all of the different scenarios.
So we only need to run this once. And run this before you run the other wrappers

*/
global projectdir $MSE_network 
*global projectdir "/home/mlee/Documents/projects/GroundfishCOCA/groundfish-MSE"
*global projectdir "C:/Users/abirken/Documents/GitHub/groundfish-MSE"

global inputdir "$projectdir/data/data_raw/econ"
global outdir "$projectdir/data/data_processed/econ"
global codedir "$projectdir/preprocessing/economic"
global bio_data "$projectdir/data/data_processed/catchHistory"



/* read in and minimal process the targeting equations */
/* There are a bunch; we'll read them all in */
/* filenames for sters and outputs*/

/* NC2 post models */

global input_ster "postCSasclogitnc2.ster"
global gillnet_out "asclogit_gillnet_post_coefsnc2.txt"
global trawl_out "asclogit_trawl_post_coefsnc2.txt"

do "$codedir/asclogit_coef_export.do"




/*
there are no post 2 models.
there are no post 1 models.
there are not post nc1 models.
*/




/* These are the pre models*/


/* NC2 post models */

global input_ster "preCSasclogitnc2.ster"
global gillnet_out "asclogit_gillnet_pre_coefsnc2.txt"
global trawl_out "asclogit_trawl_pre_coefsnc2.txt"


do "$codedir/asclogit_coef_export.do"



/* NC1 models */

global input_ster "preCSasclogitnc1.ster"
global gillnet_out "asclogit_gillnet_pre_coefsnc1.txt"
global trawl_out "asclogit_trawl_pre_coefsnc1.txt"


do "$codedir/asclogit_coef_export.do"


/* 1 models */
global input_ster "preCSasclogit1.ster"
global gillnet_out "asclogit_gillnet_pre_coefs1.txt"
global trawl_out "asclogit_trawl_pre_coefs1.txt"

do "$codedir/asclogit_coef_export.do"

/* 2 models */
global input_ster "preCSasclogit2.ster"
global gillnet_out "asclogit_gillnet_pre_coefs2.txt"
global trawl_out "asclogit_trawl_pre_coefs2.txt"

do "$codedir/asclogit_coef_export.do"




/*construct prices, reshape multipliers, and bring both into the targeting dataset */
global catch_hist_file "catchHist.csv"

global canadian_catch_hist_file "Canadian_catchHist.csv"



/*name of multiplier file*/

global multiplier_file "multipliers.dta"
global multiplier_out "reshape_multipliers.dta"

global datafilename "data_for_simulations_mse.dta"






do "$codedir/stocks_in_model.do"

do "$codedir/recode_catch_limits.do"
do "$codedir/multiplier_prep.do"


/* read in the quota price coefficients*/


do "$codedir/quota_price_coef_export.do"
/* get rhs data needed for quota price predictions */
do "$codedir/quota_price_data_export.do"




do "$codedir/readin_older_catchHist.do"
do "$codedir/compute_catch_limit_deviations.do"

