version 15.1
est drop _all

/* Run this file to export coefficients from the quota price model */


global input_ster ${inputdir}/coverage_results2022_03_04.ster
global exponential_out "${outdir}/quota_price_exponential.txt"
global linear_out "${outdir}/quota_price_linear.txt"

est drop _all




/* load in models hurdle */
est describe using "/$input_ster"

local numest=r(nestresults)
forvalues est=1(1)`numest'{
	est desc using "/$input_ster", number(`est')
	local newtitle=r(title)
	est use $input_ster, number(`est')
	est store `newtitle'
}

est dir



/* read in linear model */
est restore linear_P3


mat b=e(b)
mat b=b'

mat colnames b="coefficient"
mat2txt, matrix(b) saving($linear_out) replace



/* read in exponential model */
est restore exp_P1D


mat b=e(b)
mat b=b'

mat colnames b="coefficient"
mat2txt, matrix(b) saving($exponential_out) replace

/* read in exponential model */
/*
est use $input_ster, number(2)
est store exponential

est restore exponential
mat b=e(b)
mat b=b'

mat colnames b="coefficient"
mat2txt, matrix(b) saving($exponential_out) replace



*/


