version 15.1
*global inputdir "/home/mlee/Documents/projects/GroundfishCOCA/groundfish-MSE/data/data_raw/econ"
*global outdir "/home/mlee/Documents/projects/GroundfishCOCA/groundfish-MSE/data/data_processed/econ"



/* we need hullnum-month quota prices */
use "$inputdir/$multiplier_file" if spstock2_prim=="CodGB", clear

keep aceprice month gffishingyear spstock2 hullnum

bysort hullnum month gffishingyear spstock2: keep if _n==1


replace spstock2=lower(spstock2)
replace spstock2=subinstr(spstock2,"ccgom","CCGOM",.)
replace spstock2=subinstr(spstock2,"snema","SNEMA",.)
replace spstock2=subinstr(spstock2,"gom","GOM",.)

replace spstock2=subinstr(spstock2,"gb","GB",.)


/*using q_ as quotaprice prefix respectively */
rename aceprice q_


reshape wide q_, i(hullnum gffishingyear month) j(spstock2) string

qui foreach var of varlist q_* {
replace `var'=0 if `var'==.
label variable `var' ""
}

sort gffishingyear month


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

tempfile t12
save `t12'


keep spstock2 post gffishingyear gearcat date price_lb price_lb_lag1
bysort gearcat spstock2 date: keep if _n==1

/* this is a good place to deal with the gear level prices 	*/


gen species=subinstr(spstock2,"CCGOM","",.)
replace species=subinstr(species,"GB","",.)
replace species=subinstr(species,"GOM","",.)
replace species=subinstr(species,"SNEMA","",.)

bysort date species: egen mp=mean(price_lb)
bysort date species: egen ml=mean(price_lb_lag1)





replace price_lb=mp if inlist(spstock2,"codGOM","codGB", "haddockGOM", "haddockGB", "pollock")
replace price_lb_lag1=ml if inlist(spstock2,"codGOM","codGB", "haddockGOM", "haddockGB", "pollock")

rename price_lb_lag1 p_
rename price_lb r_
drop species ml mp
reshape wide p_ r_,  i(gearcat date) j(spstock2) string
drop p_nofish r_nofish


foreach var of varlist p_* r_* {
label var `var' ""
}

/* fiddle around with dates  */
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




tempfile t3
save `t3', replace

/* set pollock and haddock equal to the same price (their maximum)*/
replace p_pollock=max(p_pollock,p_haddockGOM)
replace p_haddockGOM=p_pollock
replace p_haddockGB=p_pollock

replace r_pollock=max(r_pollock,r_haddockGOM)
replace r_haddockGOM=r_pollock
replace r_haddockGB=r_pollock


/* set the price of cod equal to the 125% of the price of the other whitefish */

replace p_codGOM=1.25*p_pollock
replace p_codGB=1.25*p_pollock
replace r_codGOM=1.25*r_pollock
replace r_codGB=1.25*r_pollock



save "$inputdir/$output_prices1", replace

use `t3', replace

/* set the price of whitefish to 80% of the price of cod*/

replace p_pollock=.8*p_codGOM
replace p_haddockGOM=.8*p_codGOM
replace p_haddockGB=.8*p_codGOM

replace r_pollock=.8*p_codGOM
replace r_haddockGOM=.8*p_codGOM
replace r_haddockGB=.8*p_codGOM

save "$inputdir/$output_prices2", replace



/*crew wage varies by vessel-spstock2 -- so does fuelprice */
use `t12', clear
keep hullnum spstock2 post gffishingyear date wkly_crew fuelprice
gen gfstart=mdy(5,1,gffishingyear)

/* pad out an extra day, where wkly_crew and fuel price for day 366 are equal to day=365 */
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

merge m:1 post gffishingyear hullnum month using `t1', keep(1 3)
assert _merge==3
drop _merge
drop month
save "$inputdir/$input_prices", replace



