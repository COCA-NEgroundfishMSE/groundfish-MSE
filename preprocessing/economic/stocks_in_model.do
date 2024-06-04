version 15.1
use "${inputdir}/${datafilename}" if gffishingyear==2011, clear
keep spstock2
duplicates drop



replace spstock2=lower(spstock2)
replace spstock2=subinstr(spstock2,"ccgom","CCGOM",.)
replace spstock2=subinstr(spstock2,"snema","SNEMA",.)
replace spstock2=subinstr(spstock2,"gom","GOM",.)

replace spstock2=subinstr(spstock2,"gb","GB",.)


save "$outdir/stocks_in_choiceset.dta", replace
