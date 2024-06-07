/*
This is code that joins legacy (pre 2010) landings and TACs to catch share era ACLs and total catch. 
It makes some graphs
It prints out the largest and smallest difference between catch and TAC, normalized by the TAC.





*/

local extra_folder "$projectdir\data\data_raw\catchHistory"
local export_csv "$projectdir\data\data_processed\catchHistory"




local image_folder `extra_folder'

import delimited "`export_csv'\catchHist.csv", clear

/* NA to . and then destring */
foreach var of varlist directedfishery sector commonpool recreational herringfishery scallopfishery statewater other smallmesh {
	replace `var'=subinstr(`var',"NA","0",.)
}
	destring, replace


keep if inlist(data_type,"Catch","ACL")




gen NS=commonpool+recreational+herring+scallop+state+other+small
gen commercial=total-recreational

keep stock year total commercial sector NS directedfishery data_type

renvars total commercial sector NS directedfishery, postfix(_)
reshape wide total commercial sector NS directedfishery, i(stock year) j(data_type) string
rename year FY


append using `extra_folder'\extra_catch_history.dta
encode stock, gen(mystock)

gen allocated=1
replace allocated=0 if inlist(stock,"Wolffish", "Southern Windowpane","Northern Windowpane","Halibut","Ocean Pout")

tsset mystock FY

replace commercial_ACL=total_ACL if commercial_ACL==.


gen comm_ratio=commercial_Catch/commercial_ACL
gen total_ratio=total_Catch/total_ACL
replace total_ratio=comm_ratio if total_ratio==. 



gen sector_ratio=sector_Catch/sector_ACL
xtline total_ratio if allocated==1, cmissing(n) xmtick(##5) tline(2010) ytitle("Catch divided by Catch Limit")
graph export "`image_folder'\total_ratio_allocated.png", as(png) replace


/* flag cod, haddock, and Yellowtail */
gen big3=0
replace big3=1 if inlist(stock,"GB Cod", "GOM Cod", "GOM Haddock", "SNE/MA Yellowtail Flounder", "GB Yellowtail Flounder", "GB Haddock")

xtline total_ratio if big3==1, cmissing(n) xmtick(##5) tline(2010) ytitle("Catch divided by Catch Limit")
xtline comm_ratio if big3==1, cmissing(n) xmtick(##5) tline(2010) ytitle("Catch divided by Catch Limit")
graph export "`image_folder'\comm_ratios1.png", as(png) replace

xtline comm_ratio total_ratio  if big3==1, cmissing(n) xmtick(##5) tline(2010) ytitle("Catch divided by Catch Limit") legend(order(1 "Non-Rec Catch/Total ACL" 2 "All catch/ACL"))




gen period="Pre2010"
replace period="Post2010" if FY>=2010
bysort stock period: egen avg_ratio=mean(comm_ratio)
replace avg_ratio=. if FY==2010
xtline comm_ratio avg_ratio if big3==1,  legend(off) cmissing(n n) xlabel(2000(5)2020) xmtick(##5) tline(2010) ytitle("Catch divided by Catch Limit") lpattern(solid dash) lwidth(medium medthick)

graph export "`image_folder'\comm_ratios_big3.png", as(png) replace


xtline comm_ratio avg_ratio if big3==0 & allocated==1,  legend(off) cmissing(n n) xmtick(##5) tline(2010) ytitle("Catch divided by Catch Limit") lpattern(solid dash)

graph export "`image_folder'\comm_ratios_all.png", as(png) replace

/* I need to get upper and lower bounds for 

Catch=ACL*(1+X)
	where X ~U[Lower, Upper]

Divide Catch by ACL and subtract.

GOM cod rec was allocated 33% (37 starting in 2020)
GOM haddock rec was allocated 27 (33.4 starting in 2020 I think )


What do I need?

1. Pre 2020
 


*/


gen errs=(commercial_Catch/commercial_ACL)
bysort stock period: egen lower_bound=min(errs)
bysort stock period: egen upper_bound=max(errs)
bysort stock period: egen mean_catch=mean(errs)


bysort stock period: gen mark=_n
list stock period mean_catch upper_bound lower_bound  if mark==1, sepby(stock)

export delimited stock period mean_catch upper_bound lower_bound using "`export_csv'\catch_limit_deviations.csv" if mark==1, replace
