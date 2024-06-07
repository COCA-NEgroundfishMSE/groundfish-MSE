/* this file prepares uses the catch and acl history data to construct an appropriate sub-ACL for the fleet in the economic model
The fleet in the economic model is the vast majority of the "sector fleet"

The ACL for groundfish stocks may be sub-allocated to 
sector
commonpool
recreational
other fisheries (herring, scallop)
state waters
other: primarily non-target mortality from other fleets managed by other FMPs.

lets define non-sector, non-rec==commonpool+herring+scallop+other+state waters


There a few reasonable ways to convert the total ACl to the sector-ACL.
I will construct a scalar sector_frac=1-(non-sector non-rec fraction)-(rec allocation fraction)
 
non-sector non-rec fraction=non-sector, non-rec catch divided by the total ACL.
	It's reasonable to pull out a single year or average over a time period.  For the counterfactual simulations, we'll just use the sector ACL. 

 
 
Rec is allocated
33.7% of GOM cod ACL and
27.5% GOM haddock ACL.  
See the last full paragraph of page 18359 of the  Framework 44 federal register.  75 FR 68 page 18356-18375 .
Other stocks do not have a rec allocation.  Since the other rec stocks don't have a sub-ACL, the rec mortality is binnedinto "other"
The primary source for these data are https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/h/groundfish_catch_accounting
*/

version 15.1
clear


import delimited "$bio_data/$canadian_catch_hist_file"

keep stock year canadacatch canadaquota
rename canadacatch catch
rename canadaquota ACL


preserve

keep stock year catch
rename catch canada
gen data_type = "Catch"

tempfile catch
save `catch', replace

restore



keep stock year ACL
rename ACL canada
gen data_type = "ACL"
append using `catch'



tempfile canada
save `canada'









import delimited "$bio_data/$catch_hist_file", stringcols(_all) clear

foreach var of varlist directedfishery sector smallmesh commonpool herringfishery recreational scallopfishery statewater other{
replace `var'="0" if strmatch(`var',"NA")
}
destring, replace
keep if inlist(data_type,"Catch","ACL")

merge 1:1 stock year data_type using `canada', keep(1 3)
replace canada=0 if _merge==1
drop _merge
replace stock=lower(stock)
gen str30 spstock2=""

replace spstock2="winterflounderGOM" if strmatch(stock,"gom winter flounder")
replace spstock2="winterflounderGB" if strmatch(stock,"gb winter flounder")
replace spstock2="winterflounderSNEMA" if strmatch(stock,"sne/ma winter flounder")
replace spstock2="winterflounderSNEMA" if strmatch(stock,"sne/ma winter flounder*")
replace spstock2="winterflounderSNEMA" if strmatch(stock,"sne winter flounder")



replace spstock2="haddockGB" if strmatch(stock,"gb haddock")
replace spstock2="haddockGOM" if strmatch(stock,"gom haddock")
replace spstock2="codGB" if strmatch(stock,"gb cod")
replace spstock2="codGOM" if strmatch(stock,"gom cod")
replace spstock2="yellowtailflounderCCGOM" if strmatch(stock,"cc/gom yellowtail flounder")
replace spstock2="yellowtailflounderGB" if strmatch(stock,"gb yellowtail flounder")
replace spstock2="yellowtailflounderSNEMA" if strmatch(stock,"sne/ma yellowtail flounder")
replace spstock2="yellowtailflounderSNEMA" if strmatch(stock,"sne yellowtail flounder")
replace spstock2="pollock" if strmatch(stock,"pollock")
replace spstock2="redfish" if strmatch(stock,"redfish")
replace spstock2="americanplaiceflounder" if strmatch(stock,"plaice")
replace spstock2="whitehake" if strmatch(stock,"white hake")
replace spstock2="halibut" if strmatch(stock,"halibut")

replace spstock2="windowpanen" if strmatch(stock,"northern windowpane")
replace spstock2="windowpanes" if strmatch(stock,"southern windowpane")
replace spstock2="wolffish" if strmatch(stock,"wolffish")
replace spstock2="oceanpout" if strmatch(stock,"ocean pout")
replace spstock2="witchflounder" if strmatch(stock,"witch flounder")

/* data entry fix*/
replace total=6700 if year==2012 & spstock2=="codGOM" & data_type=="ACL"

/* more approriate to rename "total" to US catch */
rename total US

gen total=US+canada


gen nsnr= commonpool+ herringfishery+ statewater+ scallopfishery+ other+ smallmesh+canada

preserve

/* average over all years */
qui summ year
local first =r(min)
local last =r(max)

collapse (sum) total sector recreational nsnr , by(spstock2 data_type )
reshape wide total sector nsnr recreational, i( spstock2) j(data_type) string

gen nonsector_nonrec_fraction=nsnrCatch/totalACL
gen nsnr_CA=nsnrCatch/nsnrACL
gen rec_fraction=0
/*See the last full paragraph of page 18359 of the  Framework 44 federal register.  75 FR 68 page 18356-18375 .*/
replace rec_fraction=.337 if spstock2=="codGOM"
replace rec_fraction=.275 if spstock2=="haddockGOM"
gen ns_frac=rec_fraction+nonsector_nonrec_fraction

gen sector_frac=1-ns_frac

order *ACL, after(spstock2)
keep spstock2 totalACL sector_frac nonsector_nonrec_fraction rec_fraction 
order spstock2 totalACL  nonsector_nonrec_fraction rec_fraction sector_frac 
merge 1:1 spstock2 using "$outdir/stocks_in_choiceset.dta", nogenerate

/* mark allocated multispecies, non-allocated multispecies, and non-multispecies */
gen mults_allocated=inlist(spstock2,"americanplaiceflounder","codGB","codGOM","haddockGB","haddockGOM","pollock","redfish","whitehake")
replace mults_allocated=1 if inlist(spstock2,`"winterflounderGB"', `"yellowtailflounderCCGOM"',`"yellowtailflounderGB"',`"yellowtailflounderSNEMA"',`"winterflounderSNEMA"',`"winterflounderGOM"',`"witchflounder"')

gen mults_nonalloc=inlist(spstock2,`"windowpanen"',`"windowpanes"',`"wolffish"',`"halibut"',`"oceanpout"')

gen non_mult=inlist(spstock2, `"americanlobster"',`"americanLobster"',`"monkfish"',`"other"',`"redsilveroffshorehake"',`"seascallop"',`"skates"')
replace non_mult=1 if inlist(spstock2,`"spinydogfish"',`"squidmackerelbutterfishherring"',`"summerflounder"')

/* encode stock areas */
gen stockarea="Unit"
replace stockarea="GB" if inlist(spstock2,"codGB", "haddockGB", "winterflounderGB", "yellowtailflounderGB")
replace stockarea="GOM" if inlist(spstock2,"codGOM", "haddockGOM", "winterflounderGOM")
replace stockarea="SNEMA" if inlist(spstock2, "winterflounderSNEMA", "yellowtailflounderSNEMA")
replace stockarea="CCGOM" if inlist(spstock2,"yellowtailflounderCCGOM")



rename totalACL totalACL_mt
sort spstock2
replace sector_frac=1 if sector_frac==.
replace nonsector_nonrec_fraction=0 if nonsector_nonrec_fraction==.
replace rec_fraction=0 if rec_fraction==.

foreach var of varlist  nonsector_nonrec_fraction rec_fraction sector_frac {
replace `var'=float(round(`var',0.0001))
}
compress
export delimited using "$outdir/catch_limits_`first'_`last'.csv", replace datafmt
restore

/* just 2017 data */

levelsof year, local(myyears)

foreach yr of local myyears{
	preserve
	keep if year==`yr'

	collapse (sum) total sector recreational nsnr , by(spstock2 data_type )
	reshape wide total sector nsnr recreational, i( spstock2) j(data_type) string

	gen nonsector_nonrec_fraction=nsnrCatch/totalACL
	gen nsnr_CA=nsnrCatch/nsnrACL
	gen rec_fraction=0
	/*See the last full paragraph of page 18359 of the  Framework 44 federal register.  75 FR 68 page 18356-18375 .*/
	replace rec_fraction=.337 if spstock2=="codGOM"
	replace rec_fraction=.275 if spstock2=="haddockGOM"
	gen ns_frac=rec_fraction+nonsector_nonrec_fraction

	gen sector_frac=1-ns_frac

	order *ACL, after(spstock2)
	keep spstock2 totalACL sector_frac nonsector_nonrec_fraction rec_fraction 
	order spstock2 totalACL  nonsector_nonrec_fraction rec_fraction sector_frac 
	merge 1:1 spstock2 using "$outdir/stocks_in_choiceset.dta", nogenerate

	/* mark allocated multispecies, non-allocated multispecies, and non-multispecies */
	gen mults_allocated=inlist(spstock2,"americanplaiceflounder","codGB","codGOM","haddockGB","haddockGOM","pollock","redfish","whitehake")
	replace mults_allocated=1 if inlist(spstock2,`"winterflounderGB"', `"yellowtailflounderCCGOM"',`"yellowtailflounderGB"',`"yellowtailflounderSNEMA"',`"winterflounderSNEMA"',`"winterflounderGOM"',`"witchflounder"')

	gen mults_nonalloc=inlist(spstock2,`"windowpanen"',`"windowpanes"',`"wolffish"',`"halibut"',`"oceanpout"')

	gen non_mult=inlist(spstock2, `"americanlobster"',`"americanLobster"',`"monkfish"',`"other"',`"redsilveroffshorehake"',`"seascallop"',`"skates"')
	replace non_mult=1 if inlist(spstock2,`"spinydogfish"',`"squidmackerelbutterfishherring"',`"summerflounder"')

	/* encode stock areas */
	gen stockarea="Unit"
	replace stockarea="GB" if inlist(spstock2,"codGB", "haddockGB", "winterflounderGB", "yellowtailflounderGB")
	replace stockarea="GOM" if inlist(spstock2,"codGOM", "haddockGOM", "winterflounderGOM")
	replace stockarea="SNEMA" if inlist(spstock2, "winterflounderSNEMA", "yellowtailflounderSNEMA")
	replace stockarea="CCGOM" if inlist(spstock2,"yellowtailflounderCCGOM")



	rename totalACL totalACL_mt
	sort spstock2
	replace sector_frac=1 if sector_frac==.
	replace nonsector_nonrec_fraction=0 if nonsector_nonrec_fraction==.
	replace rec_fraction=0 if rec_fraction==.

	foreach var of varlist  nonsector_nonrec_fraction rec_fraction sector_frac {
	replace `var'=float(round(`var',0.0001))
	}

	compress

	export delimited using "$outdir/catch_limits_`yr'.csv", replace datafmt 


	restore
}


/* year-by-years annual Sector ACLs data */

keep if data_type=="ACL"


merge m:1 spstock2 using "$outdir/stocks_in_choiceset.dta", nogenerate

/* mark allocated multispecies, non-allocated multispecies, and non-multispecies */
gen mults_allocated=inlist(spstock2,"americanplaiceflounder","codGB","codGOM","haddockGB","haddockGOM","pollock","redfish","whitehake")
replace mults_allocated=1 if inlist(spstock2,`"winterflounderGB"', `"yellowtailflounderCCGOM"',`"yellowtailflounderGB"',`"yellowtailflounderSNEMA"',`"winterflounderGOM"',`"witchflounder"')
replace mults_allocated=1  if inlist(spstock2, `"winterflounderSNEMA"') & year>=2013  

gen mults_nonalloc=inlist(spstock2,`"windowpanen"',`"windowpanes"',`"wolffish"',`"halibut"',`"oceanpout"')
replace mults_nonalloc=1  if inlist(spstock2, `"winterflounderSNEMA"') & year<=2012  

gen non_mult=inlist(spstock2, `"americanlobster"',`"americanLobster"',`"monkfish"',`"other"',`"redsilveroffshorehake"',`"seascallop"',`"skates"')
replace non_mult=1 if inlist(spstock2,`"spinydogfish"',`"squidmackerelbutterfishherring"',`"summerflounder"')

/* encode stock areas */
gen stockarea="Unit"
replace stockarea="GB" if inlist(spstock2,"codGB", "haddockGB", "winterflounderGB", "yellowtailflounderGB")
replace stockarea="GOM" if inlist(spstock2,"codGOM", "haddockGOM", "winterflounderGOM")
replace stockarea="SNEMA" if inlist(spstock2, "winterflounderSNEMA", "yellowtailflounderSNEMA")
replace stockarea="CCGOM" if inlist(spstock2,"yellowtailflounderCCGOM")


keep year spstock2 total sector mults_allocated mults_nonalloc non_mult stockarea
rename total totalACL_mt
rename sector sectorACL_mt
rename year gffishingyear

expand 13 if gffishingyear==.

sort spstock2 gffishingyear
bysort spstock2: replace gffishingyear=2009+_n if gffishingyear==.
replace sectorACL_mt=. if mults_nonalloc==1
sort spstock2 gffishingyear
order spstock2 gffishingyear totalACL_mt sectorACL_mt
export delimited using "$outdir/annual_sector_catch_limits.csv", replace datafmt

