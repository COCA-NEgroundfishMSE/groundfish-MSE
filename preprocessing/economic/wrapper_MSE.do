version 15.1
/* Order of doing stuff. */
/* Run this file to load/prep the economic data */
global projectdir $MSE_network 

global inputdir "$projectdir/data/data_raw/econ"
global outdir "$projectdir/data/data_processed/econ"
global codedir "$projectdir/preprocessing/economic"
global bio_data "$projectdir/data/data_processed/catchHistory"

/*name of main data file */
global datafilename "data_for_simulations_POSTasPOST.dta"
global datafile_split_prefix "econ_data"




/*filenames for input prices and output prices */
global output_prices "MSE_post_output_price_series.dta"
global input_prices "MSE_post_input_price_series.dta"
global quota_price_out "reshape_quota_pricesMSE.dta"
global multiplier_file "multipliers.dta"


do "$codedir/price_prep.do"

do "$codedir/econ_data_split.do"

