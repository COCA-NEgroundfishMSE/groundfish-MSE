# Load in quota price coefficients


# 
# ##############Independent variables in the Quota price equations ##########################

selection=c("quota_remaining_BOQ","QuotaFraction","Q2","Q3", "Q4","constant")
badj_GDP=c("live_priceGDP","quota_remaining_BOQ","WTswtquota_remaining_BOQ", "Q2","Q3", "Q4","constant", "proportion_observed")


#names of quota price files.
quotaprice_coefs_in<-"quota_price_linearNS.txt"
quotaprice_coefs_out<-"quotaprice_coefs_linear.Rds"


quotaprice_coefs_in<-"quota_price_exponentialNS.txt"
quotaprice_coefs_out<-"quotaprice_coefs_exponential.Rds"



##########################
# BEGIN readin of econometric model of quota price coefficients 
##########################
# p value, above which we set the coefficient to zero.  You can set this to 1.0 if you want.
thresh<-1.0

## Function to zero out coefficients that are non statistically significant##
zero_out<-function(working_coefs,pcut){
  nc<-ncol(working_coefs)
  # zero out the insignificant ones 
  wc<-2
  while(wc<nc){
    idxM<-NULL 
    idxM<-which(working_coefs[wc+1]>pcut) 
    working_coefs[,wc][idxM]<-0
    wc<-wc+2
  }
  working_coefs
}

## Function to drop out the p-values##
droppval<-function(working_coefs){
  nc<-ncol(working_coefs)
  # zero out the insignificant ones 
  wc<-nc
  while(wc>=3){
    working_coefs<-working_coefs[-wc]
    wc<-wc-2
  }
  working_coefs
}

### Code works for post-as-post and post-as-pre as long as the pre_process files are run separately  
quotaprice_coefs <- read.csv(file.path(savepath,quotaprice_coefs_in), sep="\t", header=TRUE,stringsAsFactors=FALSE)

qc_rownames<-quotaprice_coefs[,1]
#here is a good place to gsub out the ":", "_I", and _cons to constant
#qc_rownames<-gsub(":","_",qc_rownames)
qc_rownames<-gsub("_I","",qc_rownames)
qc_rownames<-gsub("_cons","constant",qc_rownames)
qc_rownames<-gsub("__","_",qc_rownames)
qc_rownames<-gsub("#","X",qc_rownames)
qc_rownames<-gsub("c\\.","",qc_rownames)
qc_rownames<-gsub("lag1Q_live_priceGDP","live_priceGDP",qc_rownames)

quotaprice_coefs<-zero_out(quotaprice_coefs,thresh)
quotaprice_coefs<-droppval(quotaprice_coefs)



# Keep the sescond row 
quotaprice_coefs<-quotaprice_coefs[,2]

#transpose and send to dataframe, fix naming, and characters
quotaprice_coefs<-as.data.frame(t(quotaprice_coefs))
colnames(quotaprice_coefs)<-qc_rownames
 


# Exponentiate Sigma and rename 
 colnames(quotaprice_coefs)[colnames(quotaprice_coefs)=="lnsigma:constant"] <- "sigma"
 quotaprice_coefs$sigma<-exp(quotaprice_coefs$sigma)
 ## Rename columns 
colnames(quotaprice_coefs)[colnames(quotaprice_coefs)=="selection:quota_remaining_BOQXrecip_ACL"] <- "selection:fraction_remaining_BOQ"
# colnames(quotaprice_coefs)[colnames(quotaprice_coefs)=="Cumulative Harvest (Log)"] <- "logh_cumul"
# colnames(quotaprice_coefs)[colnames(quotaprice_coefs)=="Primary Target"] <- "primary"
# colnames(quotaprice_coefs)[colnames(quotaprice_coefs)=="Secondary Target"] <- "secondary"
# colnames(quotaprice_coefs)[colnames(quotaprice_coefs)=="Trawl Survey Biomass (Log)"]<- "log_trawl_survey_weight"
# colnames(quotaprice_coefs)[colnames(quotaprice_coefs)=="Sector ACL (Log)"]<- "log_sector_acl"
# 
# colnames(quotaprice_coefs)<- tolower(gsub("=","",colnames(quotaprice_coefs)))



quotaprice_coefs<-as.data.table(quotaprice_coefs)
saveRDS(quotaprice_coefs, file=file.path(savepath, quotaprice_coefs_out), compress=FALSE)
rm(list=c("badj_GDP","selection","qc_rownames","quotaprice_coefs_in","quotaprice_coefs_out"))


