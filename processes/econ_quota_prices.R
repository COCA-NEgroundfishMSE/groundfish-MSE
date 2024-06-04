
# Basically a modification of the runEcon_module.

############################################################
############################################################
# Not sure if there's a cleaner place to put this.  This sets up a container data.frame for each year of the economic model. 

### Probably need to add the trawl survey (trawlsurvey) index here and then push over trawl survey values into the targeting dataset.  But you might do that in outside this function.
############################################################
############################################################

fishery_holder<-bio_params_for_econ[,c("stocklist_index","stockName","spstock2","sectorACL","nonsector_catch_mt","bio_model","SSB", "mults_allocated", "stockarea","non_mult")]
fishery_holder$underACL<-as.logical("TRUE")
fishery_holder$stockarea_open<-as.logical("TRUE")
fishery_holder$cumul_catch_pounds<-0
fishery_holder$targeted<-0

#set up a list to hold the expected revenue by date, hullnum, and target spstock2
annual_revenue_holder<-list()

#set up a list to hold the date, spstock2, and aggregate metrics, like open/closed status and cumulative catch
annual_fishery_status_holder<-list()
#Initialize the most_recent_target data.table. 
#This could move to preprocessing; I'll need to set one up for the entire simulation dataset (all 6 years)
# You need to save it as a .RDS and then read.  And you need to figure out what to do with your merge statements In order to keep *all*
# most_recent_target<-readRDS()
if(y == fmyearIdx){
  keepcols<-c("hullnum","spstock2","OG_choice_prev_fish")
  most_recent_target<-copy(targeting_dataset[[1]])
  most_recent_target<-most_recent_target[, ..keepcols]
  most_recent_target<-most_recent_target[spstock2!="nofish"]
  most_recent_target<-most_recent_target[OG_choice_prev_fish==1]
  setnames(most_recent_target,"OG_choice_prev_fish","targeted")
  #You should write an assert type statment that most_recent_target has >=1 rows.
}


############################################################
############################################################
# BEGIN ECON MODULE 
# Ideally, everthing from here to the end should be a function.  It's inputs are:
# fishery_holder (which should contain info on the ACL, biomass or stock indices, and which stocks need biological outputs (Catch at age or survivors at age))
# Production and targeting data
############################################################
############################################################

qpl<-list()

q_fy<-0
for (day in 1:365){
# On the first day of each quarter, do something 
  if (day==1 | day==91 | day==182 | day==273){
  q_fy<-q_fy+1
  print(paste("It is quarter",q_fy))
  
  # This stuff should be a function. 
  # It should return the data.frame quarterly.
  
  qp<-get_predict_quota_prices()
  qp$quarter<-q_fy
  qpl[[q_fy]]<-qp
   }
}
    

qpD<-do.call(rbind.data.frame, qpl)
qpD<-round(qpD, digits=3)



