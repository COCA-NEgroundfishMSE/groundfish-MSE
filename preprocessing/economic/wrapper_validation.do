version 15.1
/* Order of doing stuff. */
/* Run this file to load/prep the economic data */
global projectdir $MSE_network 
*global projectdir "/home/mlee/Documents/projects/GroundfishCOCA/groundfish-MSE"
*global projectdir "C:/Users/abirken/Documents/GitHub/groundfish-MSE"

global inputdir "$projectdir/data/data_raw/econ"
global outdir "$projectdir/data/data_processed/econ"
global codedir "$projectdir/preprocessing/economic"
global bio_data "$projectdir/data/data_processed/catchHistory"


/*name of main data file */
global datafilename "data_for_simulations_POSTasPOST.dta"
global datafile_split_prefix "POSTasPOST"

/*filenames for input prices,quota prices, and output prices */
global output_prices "output_price_series_valid.dta"
global input_prices "input_price_series_valid.dta"
global quota_price_out "reshape_quota_prices_valid.dta"
global multiplier_file "multipliers.dta"


do "$codedir/price_prep.do"
do "$codedir/econ_data_split.do"

