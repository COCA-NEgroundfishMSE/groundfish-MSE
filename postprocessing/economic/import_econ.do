/* Order of doing stuff. */
/* Run this file to load/prep the economic results 

The simulation code stores the economic results as CSV files inside folders with the naming pattern
results_YYYY_MM_DD_HH_MM_SS

There should be more than 1 CSV in each folder.  Each has the prefix econ_
*/
version 15.1

/* setup folders */
global projectdir $MSEprojdir
global codedir "$projectdir/postprocessing/economic"
global process_results "$projectdir/results/econ/process"
cap mkdir $process_results

/********************************************/
/* Locals to import Results from the ALL simulations -- this may take a long time */
/********************************************/
/* Find all the folders that are start with"results_"; sort them in alphabetical order and save the last one.*/
local dirlist: dir "$projectdir" dirs "results_*"


/********************************************/
/* Locals to import Results from the most recent simulation */
/********************************************/
/* Find all the folders that are start with"results_"; sort them in alphabetical order and save the last one.*/
local dirlist: dir "$projectdir" dirs "results_*"
local dirlist: list sort local dirlist
local wc: word count `dirlist'
local dirlist: word `wc' of `dirlist'



local filesstore

foreach working of local dirlist{
local raw_results "$projectdir/`working'/econ/raw"



/* stata's dir does not get the file path, just the name, so it's easiest to cd to that folder and do things*/
cd `raw_results'

local datetime: subinstr local working "results_" ""
local date=substr("`datetime'",1,10)

local imports: dir "." files "econ_`date'*.csv"

*local imports: dir "." files "*.csv"

	foreach l of local imports{
		tempfile new
		local filesstore `"`filesstore'"`new'" "'  
		clear
		import delimited `l'
		qui count
		if r(N)>=1{
		gen str30 sim="`datetime'"
		gen dtsim=clock(sim,"YMDhms")
		format dtsim %tc
		drop sim
		}
		
		qui save `new', emptyok
	}
}
clear
append using `filesstore'

gen caldate=mdy(5,1,y)+doffy-1

save "$process_results/results_`date'.dta", replace




/********************************************/
/*Sample graphing code
 targets by day, across replicates */
/********************************************/
gen target=1
gen month=mofd(caldate)
format month %tm

collapse (count) target, by(month spstock2 r m)

encode spstock2, gen(mys)
 keep if r==1 & m==1
tsset mys month
xtline target



/********************************************/
/*Sample graphing code
 catch by day, across replicates */
/********************************************/

use "$process_results/results_`date'.dta", replace
gen month=mofd(caldate)
format month %tm

collapse (sum) c_*, by(month r m)

keep if r==1 & m==1
tsset month

reshape long c_, i(r m month) j(spstock2) string
label var c_ "catch"
encode spstock2, gen(mys)
tsset mys month
xtline c_


