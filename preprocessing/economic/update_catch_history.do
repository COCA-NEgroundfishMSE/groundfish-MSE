
/* you manually collected the 2018-2022 ACLs, Catch, Landings, and Discards 
	from ://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/h/groundfish_catch_accounting
		and copy/pasting the html tables into csv.

	turn off commas to delimit thousands.

		This isn't really intended to be a turnkey piece of code. It would be quite slick to automatically grab the data in the tables. but since it's done so infrequently, I'm not going to bother coding that up.
*/

global projectdir $MSE_network 

*global inputdir "$projectdir/data/data_raw/catchHistory"
*global outdir "$projectdir/data/data_processed/econ"
*global codedir "$projectdir/preprocessing/economic"
global bio_data "$projectdir/data/data_processed/catchHistory"

/*rename the old data 
I turned off the ,replace option intentionally. This will stop execution if catchHist_old.csv already exists. */
copy ${bio_data}/catchHist.csv ${bio_data}/catchHist_old.csv



import delimited "${bio_data}\catchHist2018_2022.csv", delimiter("") case(preserve) clear 
tostring Recreational, replace force
tostring SmallMesh, replace
rename year Year

/* a little data cleaning */
foreach var of varlist Commercial Sector CommonPool Recreational HerringFishery ScallopFishery StateWater Other SmallMesh{
	replace `var'="NA" if `var'=="-"
	replace `var'="NA" if `var'=="."
	replace `var'="NA" if `var'==""

}
replace Total="" if Total=="NA"
replace Total="" if Total=="-"
destring Total, replace

tempfile t1
save `t1', replace

clear
/* load in existing data and append the new data to the bottom */
import delimited "${bio_data}\catchHist_old.csv", delimiter("") case(preserve) clear
append using `t1'
/* tidy up the Stock variable */
replace Stock="SNE/MA Yellowtail Flounder" if Stock=="SNE Yellowtail Flounder"
replace Stock="GB Cod" if Stock=="GB cod"
replace Stock="GOM Cod" if Stock=="GOM cod"


tostring Total, replace usedisplayformat force


export delimited "${bio_data}\catchHist.csv", delimiter(",") replace
