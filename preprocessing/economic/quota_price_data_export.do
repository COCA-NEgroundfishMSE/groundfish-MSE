global data_main "C:/Users/Min-Yang.Lee/Documents/aceprice/data_folder/main"
global vintage_string "2022_03_04"
local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
use `prices', clear

drop if inlist(stockcode, 1818,9999)
drop if fishing_year<=2009
notes drop _dta
order fishing_year q_fy dateq stockcode stock_id spstock2 badj live_price* fGDP proportion_observed
keep fishing_year q_fy dateq stockcode stock_id spstock2 badj live_price* fGDP proportion_observed

rename dateq dateqfy
gen dateq=dateqfy+1



/* pull the seafood PPI and GDPDEF.  */

preserve
clear

local b1 "2012q1"
local baseq=quarterly("`b1'","Yq")

import fred WPU0223 GDPDEF,  daterange(2009-01-01 .) aggregate(quarterly,avg) clear
gen dateq=qofd(daten)
drop daten datestr
format dateq %tq

/* rebase the seafood PPI so it is consistent with the GDPDEF base year */
foreach var of varlist  WPU0223 GDPDEF{
	gen base`var'=`var' if dateq==`baseq'
	sort base`var'
	replace base`var'=base`var'[1] if base`var'==.
	replace `var'=`var'/base`var'*100
	notes `var' : rebased to `b1'
	drop base`var'
}
sort dateq


gen WPU_F=WPU0223 if dateq==yq(2016,1)
sort WPU_F
replace WPU_F=WPU_F[1] if WPU_F==.

gen GDP_F=GDPDEF if dateq==yq(2010,1)
sort GDP_F
replace GDP_F=GDP_F[1] if GDP_F==.

gen fGDPtoSFD=WPU_F/GDP_F
scalar fGDPtoSFD=fGDPtoSFD[1]





local b1 "2016Q1"
local baseq=quarterly("`b1'","Yq")

import fred WPU0223 ,  daterange(2009-01-01 .) aggregate(quarterly,avg) clear
gen dateq=qofd(daten)
drop daten datestr
format dateq %tq

foreach var of varlist  WPU0223{
	gen base`var'=`var' if dateq==`baseq'
	sort base`var'
	replace base`var'=base`var'[1] if base`var'==.
	gen f`var'_`b1'=`var'/base`var'
	notes f`var'_`b1': divide a nominal price or value by this factor to get real `basey' prices or values
	notes f`var'_`b1': multiply a real `basey' price or value by this factor to get nominal prices or values
	notes `var': raw index value
	drop base`var'
}
sort dateq 
order dateq f*`b1' 
tsset dateq

tempfile deflator
save `deflator', replace
clear
restore
merge m:1 dateq using `deflator', keep(1 3)
assert _merge==3
drop _merge


drop WPU0223*
drop fWPU0223*
drop dateq

gen fGDPtoSFD=scalar(fGDPtoSFD)



notes fGDPtoSFD: 2010 GDPDEF prices multiplied by this produces 2016 PPI Seafood prices
notes fGDPtoSFD: 2016 PPI Seafood prices divided by this produces 2010 GDPDEF prices





*save "${MSEprojdir}/data/data_raw/econ/quarterly_prices_${vintage_string}.dta", replace


drop if inlist(stockcode,2,4)
decode stockcode, gen(stock_string)
rename fishing_year gffishingyear
sort gffishingyear q_fy stockcode spstock2


drop if gffishingyear>=2020

export delimited gffishingyear q_fy stockcode stock_string spstock2 live_priceGDP fGDPtoSFD proportion_observed using "${MSE_network}/data/data_processed/econ/quarterly_pricesU_${vintage_string}.csv", delimiter(",") nolabel replace
drop if gffishingyear>2015

export delimited gffishingyear q_fy stockcode stock_string spstock2 live_priceGDP fGDPtoSFD proportion_observed using "${MSE_network}/data/data_processed/econ/quarterly_prices_${vintage_string}.csv", delimiter(",") nolabel replace
