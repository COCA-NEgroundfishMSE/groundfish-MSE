/* code to make a daily price and expected price dataset 
Need to run this on a full dataset. we only need it for the "post" period now, I think.*/



global projectdir $MSEprojdir 
global datafilename "data_for_simulations_POSTasPOST.dta"
global output_prices "output_price_series_valid.dta"




use "$inputdir/$datafilename", clear
cap notes drop _all
ds
local all `r(varlist)'
display "`all'"
foreach var of varlist _all {
	_strip_labels `var'
	label var `var' ""
}

replace spstock2=lower(spstock2)
replace spstock2=subinstr(spstock2,"ccgom","CCGOM",.)
replace spstock2=subinstr(spstock2,"snema","SNEMA",.)
replace spstock2=subinstr(spstock2,"gom","GOM",.)

replace spstock2=subinstr(spstock2,"gb","GB",.)



keep spstock2 post gffishingyear gearcat date price_lb price_lb_lag1
bysort gearcat spstock2 date: keep if _n==1

rename price_lb_lag1 p_
rename price_lb r_
reshape wide p_ r_,  i(gearcat date) j(spstock2) string
drop p_nofish r_nofish

foreach var of varlist p_* r_* {
label var `var' ""
}

gen gfstart=mdy(5,1,gffishingyear)

gen doffy=date-gfstart+1
drop gfstart date
expand 2 if doffy==365, gen(myg)
replace doffy=366 if myg==1


bysort gearcat gffishingyear doffy: gen marker=_N
drop if marker==2 & myg==1
cap drop marker myg
/* only 1 obs per day */
bysort gearcat gffishingyear doffy: assert _N==1
order post gearcat gffishingyear doffy
sort post gearcat gffishingyear doffy


local gillstocks americanlobster codGB codGOM haddockGOM monkfish other pollock skates spinydogfish whitehake yellowtailflounderCCGOM

foreach l of local gillstocks{
di "looking at `l'"
assert p_`l'~=. if gearcat=="GILLNETS"
assert r_`l'~=. if gearcat=="GILLNETS"
}


local trawlstocks americanplaiceflounder codGB codGOM haddockGB haddockGOM monkfish other pollock redfish redsilveroffshorehake seascallop squidmackerelbutterfishherring summerflounder whitehake winterflounderGB winterflounderGOM witchflounder yellowtailflounderCCGOM yellowtailflounderGB yellowtailflounderSNEMA

foreach l of local trawlstocks{
di "looking at `l'"
assert p_`l'~=. if gearcat=="TRAWL"
assert r_`l'~=. if gearcat=="TRAWL"
}


save "$inputdir/$output_prices", replace
