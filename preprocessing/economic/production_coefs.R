# Read in Production and Targeting coefficients to RDS  
# Tested working. Make a small change if we want to get different regression results (there are 4 sets of models for each gear, we haven't picked a "best " model yet).

##########################
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

### Code works for post-as-post and post-as-pre as long as the pre_process files are run separately  
production_coefs <- read.csv(file.path(rawpath,production_coef_in), sep="\t", header=TRUE,stringsAsFactors=FALSE)

production_coefs<-zero_out(production_coefs,thresh)
production_coefs<-droppval(production_coefs)

#push the first column into the row names and drop that column
rownames(production_coefs)<-production_coefs[,1]
production_coefs<-production_coefs[,-1]
#transpose and send to dataframe, fix naming, and characters
production_coefs<-as.data.frame(t(production_coefs))
# 
# ### Bring together 
# production_coefs[setdiff(names(production_coefs_post), names(production_coefs))] <- NA
# production_coefs_post[setdiff(names(production_coefs), names(production_coefs_post))] <- NA
#production_coefs<-production_coefs_post
#production_coefs<-rbind(production_coefs,production_coefs_post)

#rm(production_coefs_post)
#take the rownames, push them into a column, and make sure they are characters. un-name the rows
model <- rownames(production_coefs)
production_coefs<-cbind(model,production_coefs)
production_coefs$model<-as.character(production_coefs$model)
rownames(production_coefs)<-NULL


# parse the "model" string variable to facilitate merging to production dataset
production_coefs<-separate(production_coefs,model,into=c("gearcat","spstock2","post"),sep="[_]", remove=TRUE)

## Rename columns 
### First, Unlabel.  Strip out the equal signs. Prepend "alpha_" to all
colnames(production_coefs)[colnames(production_coefs)=="Number of Crew (Log)"] <- "log_crew"
colnames(production_coefs)[colnames(production_coefs)=="Trip Length Days (Log)"] <- "log_trip_days"
colnames(production_coefs)[colnames(production_coefs)=="Cumulative Harvest (Log)"] <- "logh_cumul"
colnames(production_coefs)[colnames(production_coefs)=="Primary Target"] <- "primary"
colnames(production_coefs)[colnames(production_coefs)=="Secondary Target"] <- "secondary"
colnames(production_coefs)[colnames(production_coefs)=="Trawl Survey Biomass (Log)"]<- "log_trawl_survey_weight"
colnames(production_coefs)[colnames(production_coefs)=="Sector ACL (Log)"]<- "log_sector_acl"

colnames(production_coefs)<- tolower(gsub("=","",colnames(production_coefs)))


production_coefs<-production_coefs[,c(which(colnames(production_coefs)!="constant"),which(colnames(production_coefs)=="constant"))]
production_coefs<-production_coefs[,c(which(colnames(production_coefs)!="rmse"),which(colnames(production_coefs)=="rmse"))]

colnames(production_coefs)[5:ncol(production_coefs)-1]<-paste0("alpha_",colnames(production_coefs[5:ncol(production_coefs)-1]))
# you will eventually merge on post, gearcat, and spstock
production_coefs$spstock2<-tolower(production_coefs$spstock2)
production_coefs$post<-as.numeric(production_coefs$post)

#You've zero filled the n/a's in the prediction code, but fine to keep here.
############ I think the safest thing to do is fill any NA coefficients with zeros.
production_coefs[is.na(production_coefs)] <- 0
############ In the data, fill any corresponding NAs also with zeros -- this would mostly be biomass or fishing year

production_coefs<-as.data.table(production_coefs)

pc_colnames<-colnames(production_coefs)
if (!('alpha_fy2004' %in% pc_colnames)){
  production_coefs$alpha_fy2004<-0
}

if (!('alpha_fy2005' %in% pc_colnames)){
  production_coefs$alpha_fy2005<-0
}
if (!('alpha_fy2006' %in% pc_colnames)){
  production_coefs$alpha_fy2006<-0
}
if (!('alpha_fy2007' %in% pc_colnames)){
  production_coefs$alpha_fy2007<-0
}
if (!('alpha_fy2008' %in% pc_colnames)){
  production_coefs$alpha_fy2008<-0
}
if (!('alpha_fy2009' %in% pc_colnames)){
  production_coefs$alpha_fy2009<-0
}

if (!('alpha_fy2010' %in% pc_colnames)){
  production_coefs$alpha_fy2010<-0
}
if (!('alpha_fy2011' %in% pc_colnames)){
  production_coefs$alpha_fy2011<-0
}
if (!('alpha_fy2012' %in% pc_colnames)){
  production_coefs$alpha_fy2012<-0
}
if (!('alpha_fy2013' %in% pc_colnames)){
  production_coefs$alpha_fy2013<-0
}
if (!('alpha_fy2013' %in% pc_colnames)){
  production_coefs$alpha_fy2013<-0
}
if (!('alpha_fy2014' %in% pc_colnames)){
  production_coefs$alpha_fy2014<-0
}
if (!('alpha_fy2015' %in% pc_colnames)){
  production_coefs$alpha_fy2015<-0
}





production_coefs$spstock2<- gsub("gb","GB",production_coefs$spstock2)
production_coefs$spstock2<- gsub("ccgom","CCGOM",production_coefs$spstock2)
production_coefs$spstock2<- gsub("gom","GOM",production_coefs$spstock2)
production_coefs$spstock2<- gsub("snema","SNEMA",production_coefs$spstock2)

saveRDS(production_coefs, file=file.path(savepath, production_outfile), compress=FALSE)



