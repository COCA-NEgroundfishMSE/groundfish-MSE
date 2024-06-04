version 15.1

est use ${inputdir}/$input_ster, number(1)
est store gillnetasc

est use  ${inputdir}/$input_ster, number(2)
est store trawlasc



est restore gillnetasc
mat b=e(b)
mat b=b'

mat colnames b="coefficient"
mat2txt, matrix(b) saving(${inputdir}/$gillnet_out) replace



est restore trawlasc
mat b=e(b)
mat b=b'

mat colnames b="coefficient"
mat2txt, matrix(b) saving(${inputdir}/$trawl_out) replace






