# Read in post prices and save those to Rds 



mults <- read.dta13(file.path(rawpath, input_price_loc))
mults<-as.data.table(mults)


if (yrstub=="POSTasPRE"){
  mults[, c(quotaprice_zero_cf) :=0]
} 
 


multipre<-mults[post==0]
multipre[, post:= NULL]

multipre<-split(multipre,multipre$gffishingyear)

multipost<-mults[post==1]
multipost[, post:= NULL]

multipost<-split(multipost,multipost$gffishingyear)


saveRDS(multipost, file=file.path(savepath, input_postoutfile), compress=FALSE)
saveRDS(multipre, file=file.path(savepath, input_preoutfile),compress=FALSE)
rm(list=c("multipre", "multipost", "mults"))


