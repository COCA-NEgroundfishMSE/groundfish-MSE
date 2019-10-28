*global inputdir "/home/mlee/Documents/projects/GroundfishCOCA/groundfish-MSE/data/data_raw/econ"
*global outdir "/home/mlee/Documents/projects/GroundfishCOCA/groundfish-MSE/data/data_processed/econ"



/* we monthly quota prices */
use "$inputdir/$multiplier_file" if spstock2_prim=="CodGB", clear

keep aceprice month gffishingyear spstock2

bysort month gffishingyear spstock2: keep if _n==1


replace spstock2=lower(spstock2)
replace spstock2=subinstr(spstock2,"ccgom","CCGOM",.)
replace spstock2=subinstr(spstock2,"snema","SNEMA",.)
replace spstock2=subinstr(spstock2,"gom","GOM",.)

replace spstock2=subinstr(spstock2,"gb","GB",.)


/*using q_ as quotaprice prefix respectively */
rename aceprice q_


reshape wide q_, i(gffishingyear month) j(spstock2) string

qui foreach var of varlist q_* {
replace `var'=0 if `var'==.
label variable `var' ""
}

sort gffishingyear month


compress

gen post=0
replace post=1 if gffishingyear>=2010
order post gffishingyear month

notes  drop _all 
tempfile t1

save `t1', replace

















/* Construct prices at the spstock2-date level */

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

save "$inputdir/$datafilename", replace



keep spstock2 post gffishingyear gearcat date price_lb price_lb_lag1
bysort gearcat spstock2 date: keep if _n==1


replace spstock2=lower(spstock2)
replace spstock2=subinstr(spstock2,"ccgom","CCGOM",.)
replace spstock2=subinstr(spstock2,"snema","SNEMA",.)
replace spstock2=subinstr(spstock2,"gom","GOM",.)
replace spstock2=subinstr(spstock2,"gb","GB",.)

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
bysort gearcat gffishingyear doffy: assert _N==1
order post gearcat gffishingyear doffy
sort post gearcat gffishingyear doffy
save "$inputdir/$output_prices", replace



/*crew wage varies by vessel-spstock2 -- so does fuelprice */
use "$inputdir/$datafilename", clear
keep hullnum spstock2 post gffishingyear date wkly_crew fuelprice
gen gfstart=mdy(5,1,gffishingyear)


replace spstock2=lower(spstock2)
replace spstock2=subinstr(spstock2,"ccgom","CCGOM",.)
replace spstock2=subinstr(spstock2,"snema","SNEMA",.)
replace spstock2=subinstr(spstock2,"gom","GOM",.)
replace spstock2=subinstr(spstock2,"gb","GB",.)


/* pad out an extra day, where wkly_crew and fuel price for day 366 are equal to day=265 */
gen doffy=date-gfstart+1
expand 2 if doffy==365, gen(myg)
replace doffy=366 if myg==1

bysort hullnum spstock2 post gffishingyear doffy: gen marker=_N
drop if marker==2 & myg==1 
bysort hullnum spstock2 post gffishingyear doffy: assert _N==1
gen month=month(date)

drop gfstart date myg marker
order post gffishingyear hullnum spstock2 doffy
sort post gffishingyear hullnum spstock2 doffy

merge m:1 post gffishingyear month using `t1', keep(1 3)
assert _merge==3
drop _merge
drop month
save "$inputdir/$input_prices", replace



