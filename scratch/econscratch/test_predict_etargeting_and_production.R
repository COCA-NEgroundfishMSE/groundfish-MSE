# some code to run the economic module.
# This code will eventually take in the catch limits, by stock, and either biomass  


############################################################
#Preamble stuff that is contained in other places.
#load in functions
#set class to not HPCC
#load libraries
#declare some paths to read and save things that I'm scratchpadding
############################################################

#### Set up environment ####
rm(list=ls())
# Which management procedures csv do you want to read:
#mprocfile<-"mproc.csv"
#mprocfile<-"mprocTest.csv"
mproc_manual<-"mprocEcon_validate.csv"
mproc_manual<-"mprocEcon_counterfactual_closemult.csv"

#runSetup.R loads things and sets them up. This is used by the integrated simulation, so be careful making changes with it. Instead, overwrite them using the setupEcon_extra.R file.
source('processes/runSetup_Econonly.R')

#the base runSetup.R runs source('processes/genBaselineACLs.R') to set up ACLs in the data.table econ_baseline.
# rather than change that file, we'll just overwrite with the econ-only version in the next step.

source('processes/genBaselineACLs_Econonly.R')


####################These are temporary changes for testing ####################
mproc_bak<-mproc
mproc<-mproc_bak[1:4,] #selects validation, counterfactual and counterfactual_single 
#mproc<-mproc_bak[17:20,] #selects "validation single"  

mproc$EconType<-"Multi"
mproc$CatchZero<-"FALSE"
mproc$LandZero<-"FALSE"

nrep<-1
# yrs contains the calendar years, the calendar year corresponding to y is yrs[y].  we want to go 'indexwise' through the year loop.
# I want to start the economic model at fmyear=2010 and temporarily end it in 2011
start_sim<-2010
end_sim<-2015

fyear<-which(yrs == start_sim)
nyear<-which(yrs == end_sim)

####################End Temporary changes for testing ####################

#set the rng state based on system time.  Store the random state.  

#set the rng state based on system time.  Store the random state.  
# if we use a plain old date (seconds since Jan 1, 1970), the number is actually too large, but we can just rebase to seconds since Jan 1, 2018.

start<-Sys.time()-as.POSIXct("2018-01-01 00:00:00",tz="","%Y-%m-%d %H:%M:%S")
start<-as.double(start)*100
set.seed(start)

oldseed_ALL <- .Random.seed
showProgBar<-TRUE    

####################End Parameter and storage Setup ####################
#This depends on mproc, fyear, and nyear. So it should be run *after* it is reset. I could be put in the runSetup.R script. But since I'm  adjusting fyear and nyear temporarily, I need it here (for now).

source('processes/setupYearIndexing_Econ.R')

# for(r in 1:nrep){
# 
# for(m in 1:nrow(mproc)){
#   model = mproc$EconData[m]
#   
#   
#   tchars<-nchar(model)
#   modelno<-substr(model,tchars,tchars)
#   
#   manage_counter<-0
  
r<-1
m<-4
model = mproc$EconData[m]


tchars<-nchar(model)
modelno<-substr(model,tchars,tchars)

manage_counter<-0


  source('processes/setupEconType.R')

y<-fyear

source('processes/withinYearAdmin.R')
if(y>=fmyearIdx){
  manage_counter<-manage_counter+1 #this only gets incremented when y>=fmyearIdx
}



source('processes/loadEcon2.R')

# subset just the current year of regulations
econ_baseline_yearly<-econ_baseline[gffishingyear==yrs[y]]
bio_params_for_econ <- get_bio_for_econ_only(stock,econ_baseline_yearly)


#Instead of doing this line, you'll want to copy/paste pieces from it and run them by hand.
# source('processes/runEcon_moduleonly.R')

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
  if(y == fmyearIdx){
    keepcols<-c("hullnum","spstock2","OG_choice_prev_fish")
    most_recent_target<-copy(targeting_dataset[[1]])
    most_recent_target<-most_recent_target[, ..keepcols]
    most_recent_target<-most_recent_target[spstock2!="nofish"]
    most_recent_target<-most_recent_target[OG_choice_prev_fish==1]
    setnames(most_recent_target,"OG_choice_prev_fish","targeted")
    
  }
mrt_bak<-copy(most_recent_target)

for (day in 1:365){
  
set.seed(2)
#day<-100

working_targeting<-copy(targeting_dataset[[day]])
#working_targeting<-working_targeting[hullnum!="1031278"]
#working_targeting<-working_targeting[hullnum!="1040383"]

working_targeting$OG_choice_prev_fish<-working_targeting$choice_prev_fish

working_targeting<-get_predict_eproduction(working_targeting)
#This does the day limits  
#working_targeting [, harvest_sim:= ifelse(is.na(dl_primary), harvest_sim, ifelse(harvest_sim >= dl_primary, dl_primary, harvest_sim))]
working_targeting[spstock2=="nofish", harvest_sim:=0L]
working_targeting[, delta:=harvest_sim-h_hat]

#working_targeting [, harvest_sim:= ifelse(is.na(dl_primary), harvest_sim, ifelse(harvest_sim >= dl_primary, dl_primary, harvest_sim))]


  summary(working_targeting$delta)
  setcolorder(working_targeting, c("delta", "harvest_sim","h_hat"))
  #setorder(working_targeting, -delta)
  
  #alphass<-grep("^alpha",colnames(working_targeting) , value=TRUE)


# Update choice_prev_fish
    working_targeting[most_recent_target, choice_prev_fish:=targeted, on=c("hullnum","spstock2")]
    working_targeting[is.na(choice_prev_fish), choice_prev_fish := 0]
    
# working_targeting$choice_prev_fish<-working_targeting$OG_choice_prev_fish
    
  working_targeting$exp_rev_bak<-working_targeting$exp_rev_total

  
  saveloc_wt<-paste0("working_targeting",day)
  assign(saveloc_wt,working_targeting)
  
  
  
  
    working_targeting<-joint_adjust_allocated_mults(working_targeting,fishery_holder, econtype)
    working_targeting<-joint_adjust_others(working_targeting,fishery_holder, econtype)
    
    
  #TESTED TO HERE.
  # In testing, we have to zero out the dl_ variables
    
    
   dl_vars<-grep("^dl_",colnames(working_targeting) , value=TRUE)
   working_targeting[,(dl_vars):=NA]
    working_targeting<-get_joint_production(working_targeting,spstock2s) 
    
    # adjust for DAS costs.
    # subtract off das_costs from expected and actual  revenue.
    # The _das variable is computed exactly the same as the exp_rev_total variable. 
    # If necessary the DAS and/or QUOTA costs should be set to zero either in the data  
    working_targeting[, exp_rev_total:=exp_rev_total-das_cost]
    working_targeting[, actual_rev_total:=actual_rev_total-das_cost]

    working_targeting[spstock2=="nofish", exp_rev_total:=0L]
    working_targeting[spstock2=="nofish", actual_rev_total:=0L]
    
    #rescale
    working_targeting[, exp_rev_total:=exp_rev_total/1000]
    working_targeting[, actual_rev_total:=actual_rev_total/1000]
    #fill the _das variables
    working_targeting[, exp_rev_total_das:=exp_rev_total]
    working_targeting[, actual_rev_total_das:=actual_rev_total]
    
  working_targeting[, deltar:=abs(exp_rev_total-exp_rev_bak)]
  summary(working_targeting$deltar)
  setcolorder(working_targeting, c("deltar", "exp_rev_total", "exp_rev_bak"))
  setorder(working_targeting,-deltar)

  
    
  #the data a sset choice_prev_fish=0
  
  
  
  # Predict targeting
  trips<-get_predict_etargeting(working_targeting)
  
  trips[, deltapr:=abs(prhat-pr_hat_2)]
  trips[, relpr:=deltapr/pr_hat_2]
  
  trips[, deltaxb:=abs(xb-xb_hat_2)]
  setcolorder(trips, c("deltapr", "relpr","deltaxb", "xb", "xb_hat_2", "prhat","pr_hat_2"))
  setorder(trips,-relpr)
  
  
  trips<-zero_out_closed_areas_asc_cutout(trips,fishery_holder)
  
  # draw trips probabilistically.  A trip is selected randomly from the choice set. 
  # The probability of selection is equal to prhat
  trips<-get_random_draw_tripsDT(trips)
  #drop out trip that did not fish (they have no landings or catch). 
  #trips<-trips[spstock2!="nofish"]
  
  catches<-get_reshape_catches(trips)
  landings<-get_reshape_landings(trips)
  
  #I don't think I need to do this.
  target_rev<-get_reshape_targets_revenues(trips)
  #I don't think I need to do this.
  
  
  
  # update the fishery holder dataframe
  
  
  # left join landings into fishery_holder.  Replace fishery holder's cumul_catch_pounds=cumul_catch_pounds+daily_catch  remove daily_catch?  
  
  fishery_holder<-fishery_holder[catches, on="spstock2"]
  fishery_holder[, cumul_catch_pounds:= cumul_catch_pounds+daily_pounds_caught]
  fishery_holder[, daily_pounds_caught :=NULL]
  
  fishery_holder<-get_fishery_next_period_areaclose(fishery_holder)
  savelist<-c("id","hullnum","spstock2","doffy","exp_rev_total","exp_rev_total_das","actual_rev_total", "gearcat")
  savelist<-c("id","hullnum","spstock2","doffy","exp_rev_total","exp_rev_total_das", "actual_rev_total", "gearcat","choice_prev_fish","OG_choice_prev_fish")
  
  mm<-c(grep("^c_",colnames(trips), value=TRUE),grep("^l_",colnames(trips), value=TRUE),grep("^r_",colnames(trips), value=TRUE))
  savelist=c(savelist,mm)
  # Save the trip-level and fishery level metrics to the appropriate places
  annual_revenue_holder[[day]]<-trips[, ..savelist]
  
  
  savelist2<-c("spstock2","sectorACL","bio_model","SSB","mults_allocated", "stockarea","underACL", "stockarea_open","cumul_catch_pounds", "sectorACL_pounds")
  
  annual_fishery_status_holder[[day]]<-fishery_holder[,..savelist2]
  annual_fishery_status_holder[[day]]$doffy<-day
  
  # prepare the trips data.table for the next iteration
  #trips<-trips[spstock2!="nofish"]
  trips<-trips[, c("spstock2","hullnum", "targeted","choice_prev_fish","OG_choice_prev_fish")]
  saveloc<-paste0("trips",day)
  setorderv(trips,"hullnum")
 
  #assign(saveloc,copy(trips))
  #setnames(trips, "spstock2","spstock2back", skip_absent=TRUE)
   #test out the state-dependence code for all equal to nofish
  #trips$spstock2<-"nofish"
  #test out the state-dependence code for all equal to codGOM
  # trips$spstock2<-"codGOM"

  #trips<-trips[spstock2!="nofish"]
  #trips[most_recent_target, spstocklag:=i.spstock2, on=c("hullnum","targeted"), all=TRUE]
  trips<-merge(trips,most_recent_target, by=c("hullnum","targeted"), all=TRUE, suffixes=c("T","MRT"))
  #overwrite with the previous the target stock is no_fish
  most_recent_target<-copy(trips)
  
  # when you get here, you have partially updated most_recent_target data.table. 
  # hullnum, targeted,
  # "spstock2T" is what theyfished today.
  # choice_prev_fish is the 0/1 indicator whether they fished spstock2T yesterday
  # OG is the initial in the input dataset, this is actually all zeros by construction
  # spstock2MRT is the spstock2 was most recently targeted. spstock2MRT cannot be "nofish"
  
  # rename spstock2T to spstock2
  setnames(most_recent_target,"spstock2T","spstock2", skip_absent=TRUE)
  
  # replace any no fish with MRT
  most_recent_target[spstock2=="nofish", spstock2 :=spstock2MRT]
  # if there are any na's replace them with MRT. Not sure how nas would occur.
  most_recent_target[is.na(spstock2), spstock2 :=spstock2MRT]
  
  #drop extra columns.
  keepcols<-c("hullnum","spstock2","targeted")
  most_recent_target<-most_recent_target[, ..keepcols]

  }

# #setnames(trips, "targeted","targeted1", skip_absent=TRUE)
# #setorderv(trips,"hullnum")
# 
# 
# setcolorder(working_targeting1,c("hullnum","spstock2","choice_prev_fish","OG_choice_prev_fish"))
# setcolorder(working_targeting2,c("hullnum","spstock2","choice_prev_fish","OG_choice_prev_fish"))
# 
# setorderv(working_targeting1,c("hullnum","spstock2","choice_prev_fish","OG_choice_prev_fish"))
# setorderv(working_targeting2,c("hullnum","spstock2","choice_prev_fish","OG_choice_prev_fish"))
# 
# 
# # With no updating, the OG_choice on day must always match the choice_prev 
# 
# #del21<-working_targeting2$OG_choice_prev_fish-working_targeting2$choice_prev_fish
# #summary(del21)
# test1<-working_targeting1
# test2<-working_targeting2
# test3<-working_targeting3
# 
# #del32<-working_targeting3$OG_choice_prev_fish-working_targeting2$choice_prev_fish
# #summary(del32)


# 
# With no updating, the OG_choice on day must always match the choice_prev.  PASS
# With updating, the working_targeting2$choice_prev should match trips1$spstock2 when that is NOT nofish
# and
# A.	Working_targeting1$choice_prev for all the trips1 where spstock2=nofish
# Quickest way to check – set them to codGOM or nofish
# Set trips$spstock2<-codGOM 
# I should see choice_prev_fish=1 for only spstock2==GOM  PASS
table(working_targeting3$spstock2, working_targeting3$choice_prev_fish)
table(working_targeting2$spstock2, working_targeting2$choice_prev_fish)


# A.	Check 2
# Set   trips$spstock2<-"nofish"
# the most_recent_target data table should be the same as the mrt_bak table

# the choice_prev_fish in working_targeting3 should be equalt to that in working_targeting2
table(working_targeting3$choice_prev_fish, working_targeting2$choice_prev_fish)
keepcols<-c("hullnum","spstock2","gearcat","choice_prev_fish")
working_targeting3<-working_targeting3[, ..keepcols]
working_targeting2<-working_targeting2[, ..keepcols]
working_targeting1<-working_targeting1[, ..keepcols]

wttest<-merge(working_targeting1,working_targeting2,by=c("hullnum","spstock2","gearcat"),all=TRUE)
wttest$del<-wttest$choice_prev_fish.x-wttest$choice_prev_fish.y

wttest23<-merge(working_targeting2,working_targeting3,by=c("hullnum","spstock2","gearcat"),all=TRUE)
wttest23$del<-wttest$choice_prev_fish.x-wttest$choice_prev_fish.y
summary(wttest23$del)


table(working_targeting2$spstock2, working_targeting2$choice_prev_fish)
table(working_targeting1$spstock2, working_targeting1$choice_prev_fish)

#all.equal(mrt_bak,most_recent_target)

#mm<-merge(mrt_bak,most_recent_target,by=c("hullnum","targeted"),all=TRUE)

