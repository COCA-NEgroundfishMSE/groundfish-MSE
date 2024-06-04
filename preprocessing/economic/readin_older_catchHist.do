/*
This is code that reads in legacy (pre 2010) landings and TACs.   
These were taken from 
https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports//mul.htm
*/


local extra_folder "$projectdir\data\data_raw\catchHistory"
local export_csv "$projectdir\data\data_processed\catchHistory"

local myfiles: dir "`extra_folder'" files "*.xlsx"

foreach l of local myfiles{
	import excel `extra_folder'/`l', clear allstring firstrow
	
	local newname: subinstr local l ".xlsx" ".dta"
	save `extra_folder'/`newname', replace
	
}

clear

local myfiles: dir "`extra_folder'"  files "landings*.dta"



foreach l of local myfiles{
	append using `extra_folder'/`l'
}


drop if stock==""
drop Species

order stock FY 
destring FY, replace

drop C D G H F

drop PercentofTAC
replace TargetTAC=subinstr(TargetTAC,"*","",.)
replace TargetTAC=subinstr(TargetTAC,",","",.)
replace TargetTAC=subinstr(TargetTAC,"N/A",".",.)
destring TargetTAC Landings, replace


rename TargetTAC total_ACL
rename Landings commercial_Catch


replace commercial_Catch=round(commercial_Catch/2.20462,1) if unit=="thousands of pounds"
replace total_ACL=round(total_ACL/2.20462,1) if unit=="thousands of pounds"

/* 
GOM cod rec was allocated 33% (37 starting in 2020)
GOM haddock rec was allocated 27 (33.4 starting in 2020 I think )
*/
gen commercial_ACL=total_ACL
replace commercial_ACL=commercial_ACL*0.666667 if stock=="GOM Cod"
replace commercial_ACL=commercial_ACL*0.73 if stock=="GOM Haddock"



drop unit
save `extra_folder'/extra_catch_history.dta, replace