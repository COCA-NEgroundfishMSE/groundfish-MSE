version 15.1
/* minor data cleanup */

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

levelsof gffishingyear, local(yrloc)
save "$inputdir/$datafilename", replace

/* save year-by-year */

foreach gfy of local yrloc {
preserve
keep if gffishingyear==`gfy'
cap rename log_tac log_sector_acl
cap drop spstock year hullnum2

save "$inputdir/${datafile_split_prefix}_`gfy'.dta", replace
restore
}

