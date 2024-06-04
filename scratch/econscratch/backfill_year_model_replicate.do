/*code chunk to backfill the FY, nyears, mproc from the simulation dataset. */



import delimited C:\Users\Min-Yang.Lee\Documents\groundfish-MSE\results_2020-07-31-19-06-26\stock_status_stacked.csv
drop v1
global stocks 23
global ndays 365
global nyears 6
global mprocs 4

drop doffy
drop replicate
egen doffy=seq(), from(1) to(365) block($stocks)

global sd=$stocks*$ndays
egen fy=seq(), from(2010) to(2015) block($sd)
global sdy=$sd*$nyears
egen mproc=seq(), from(1) to(4) block($sdy)
global sdym=$sdy*$mprocs

egen replicate=seq(), from(1) to(100) block($sdym)


drop year
rename fy year
drop bio_model ssb mults_allocated
label define econtype 1 "valid_pre_coefsnc1" 2 "valid_pre_coefsnc2" 3 "valid_pre_coefs1" 4 "valid_pre_coefs2"
label values mproc econtype

label define TF 1 "TRUE" 0 "FALSE"
gen under2=1 if underacl=="TRUE"
replace under2=0 if underacl=="FALSE"

label values under2 TF

drop underacl
rename under2 underacl



gen under3=1 if stockarea_open=="TRUE"
replace under3=0 if stockarea_open=="FALSE"

label values under3 TF

drop stockarea_open
rename under3 stockarea_open
compress

save "C:\Users\Min-Yang.Lee\Documents\groundfish-MSE\postprocessing\economic\daily_stock_status.dta", replace
