# Read in Production and Targeting coefficients to .Rds  
# Tested working. Make a small change if we want to get different regression results (there are 4 sets of models for each gear, we haven't picked a "best " model yet).

# BEGIN readin of econometric model of production coefficients 
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

for (coef in 1:length(models)){

# This is code to pull out ASC logit coefficients for trawl
asc_coefs <- read.csv(file.path(rawpath,trawl_targeting_coef_source[coef]), sep="\t", header=TRUE,stringsAsFactors=FALSE)
asc_coefs<-asc_coefs[,-3]

#Separate on the ":" and tidy up white space a bit
asc_coefs<-separate(asc_coefs,X,into=c("equation","variable"),sep=":", remove=TRUE, fill="right")
asc_coefs$equation<-gsub(",","", asc_coefs$equation)
asc_coefs$equation<-trimws(asc_coefs$equation, which=c("both"))
asc_coefs$variable<-gsub(",","", asc_coefs$variable)
asc_coefs$variable<-trimws(asc_coefs$variable, which=c("both"))
asc_coefs$gearcat<-"TRAWL"


#Repeat for gillnet and then stack together.
gn_coefs <- read.csv(file.path(rawpath,gillnet_targeting_coef_source[coef]), sep="\t", header=TRUE,stringsAsFactors=FALSE)
gn_coefs<-gn_coefs[,-3]


#Separate on the ":" and tidy up white space a bit
gn_coefs<-separate(gn_coefs,X,into=c("equation","variable"),sep=":", remove=TRUE, fill="right")
gn_coefs$equation<-gsub(",","", gn_coefs$equation)
gn_coefs$equation<-trimws(gn_coefs$equation, which=c("both"))
gn_coefs$variable<-gsub(",","", gn_coefs$variable)
gn_coefs$variable<-trimws(gn_coefs$variable, which=c("both"))
gn_coefs$gearcat<-"GILLNETS"
# for some reason, partial_closure is coming in as o.partial_closure for gillnets 
gn_coefs$variable[gn_coefs$variable=="o.partial_closure"] <-"partial_closure"


asc_coefs<-rbind(asc_coefs,gn_coefs)
asc_coefs$variable[asc_coefs$variable=="_cons"] <-"constant"

rm(gn_coefs)

# Split asc_coefs into two dataframes. One where equation=="spstock2" and the other where equation~="spstock2" 
asc_coefs$variable<-paste0("beta_",asc_coefs$variable)

all_coefs<-asc_coefs[which(asc_coefs$equation=="spstock2"),]
#drop the equation column. Spread
all_coefs<-all_coefs[,-1]
all_coefs<-spread(all_coefs,variable,coefficient)



asc_coefs2<-asc_coefs[which(asc_coefs$equation!="spstock2"),]
colnames(asc_coefs2)[1]<-"spstock2"

#create the "nofish" observations by duplicating the CodGOM, setting all coeffs to zero, and rbinding.
extra<-asc_coefs2[which(asc_coefs2$spstock2=="CodGOM"),]
extra$coefficient<-0 
extra$spstock2<-"nofish" 
asc_coefs2<-rbind(asc_coefs2,extra)

  


asc_coefs2<-spread(asc_coefs2,variable,coefficient)
targeting_coefs<-inner_join(asc_coefs2,all_coefs, by="gearcat")


#The "start of season" variable used to go slightly differently for gillnet and trawl
#targeting_coefs$beta_start_of_season.x[is.na(targeting_coefs$beta_start_of_season.x)] <- targeting_coefs$beta_start_of_season.y[is.na(targeting_coefs$beta_start_of_season.x)]
#targeting_coefs<-within(targeting_coefs, rm(beta_start_of_season.y))




#colnames(targeting_coefs)[colnames(targeting_coefs)=="beta_start_of_season.x"] <- "beta_start_of_season"
#colnames(targeting_coefs)[colnames(targeting_coefs)=="beta_exp_rev_total_das"] <- "beta_exp_rev_total"

#Force NAs to zero. This is legit. I promise.
targeting_coefs[is.na(targeting_coefs)]<-0
targeting_coefs<-as.data.table(targeting_coefs)

colnames(targeting_coefs)[colnames(targeting_coefs)=="beta_LApermit"] <- "beta_lapermit"
targeting_coefs$spstock2<-tolower(targeting_coefs$spstock2)



setcolorder(targeting_coefs,c("gearcat", "spstock2"))
setorder(targeting_coefs,"gearcat", "spstock2")

#targeting_coefs[, c("beta_o.das_price_mean","beta_o.das_price_mean_len"):=NULL]


targeting_coefs$spstock2<- gsub("gb","GB",targeting_coefs$spstock2)
targeting_coefs$spstock2<- gsub("ccgom","CCGOM",targeting_coefs$spstock2)
targeting_coefs$spstock2<- gsub("gom","GOM",targeting_coefs$spstock2)
targeting_coefs$spstock2<- gsub("snema","SNEMA",targeting_coefs$spstock2)


saveRDS(targeting_coefs, file=file.path(savepath, target_coef_outfile[coef]), compress=FALSE)
rm(list=c("all_coefs","asc_coefs","asc_coefs2","extra"))
}

