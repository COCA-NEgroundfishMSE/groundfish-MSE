# This code runs the economic module.
# It is essentially an alternate to the "get_implementationF" function.  
# It takes in 
#   Values from the stock dynamics models 
#   Data from the econometric models
#   
# And outputs F_full for each modeled stock and a dataset of daily targeting  outcomes
  

############################################################
############################################################
# Not sure if there's a cleaner place to put this.  This sets up a container data.frame for each year of the economic model. 

### Probably need to add the trawl survey (trawlsurvey) index here and then push over trawl survey values into the targeting dataset.  But you might do that in outside this function.
############################################################
############################################################

fishery_holder<-bio_params_for_econ[,c("stocklist_index","stockName","spstock2","sectorACL","nonsector_catch_mt","bio_model","SSB", "mults_allocated", "stockarea","non_mult","ln_trawlsurvey", "ln_obs_trawlsurvey")]
fishery_holder$underACL<-as.logical("TRUE")
fishery_holder$stockarea_open<-as.logical("TRUE")
fishery_holder$cumul_catch_pounds<-0
fishery_holder$targeted<-0


# Subset the fishery_holder to rows that have a biological model, and keep the spstock2 and ln_trawl_survey columns
ts<-fishery_holder[bio_model==1, c('spstock2','ln_trawlsurvey','ln_obs_trawlsurvey','sectorACL')]
#Sanity check. The actual values in the trawl survey have never been higher than 5. So, set a max at 7, just in case, which is nearly an order of magnitude higher.
ts[ln_trawlsurvey>=7, ln_trawlsurvey:=7]
ts[ln_obs_trawlsurvey>=7, ln_obs_trawlsurvey:=7]
ts[, ln_sector_acl:=log(sectorACL)]
ts[,sectorACL:=NULL]


#set up a list to hold the expected revenue by date, hullnum, and target spstock2
annual_revenue_holder<-list()
#set up a list to hold the date, spstock2, and aggregate metrics, like open/closed status and cumulative catch
annual_fishery_status_holder<-list()

#set up a list to hold the quota prices
annual_quota_price_holder<-list()


# setup a list to hold the intraseason Gini ala Birkenbach, Kazcan, Smith nature.
#Gini_stock_within_season_BKS<-list()

#Gini_fleet<-list()
#Gini_fleet_bioecon_stocks<-list()

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



q_fy<-0
w_fy<-0

qds <- c(1, 91,182,273)
weeks <-seq(from = 1, to = 365, by = 7)


for (day in 1:365){
  if (day  %in% qds){
    q_fy<-q_fy+1
  }
  if (day  %in% weeks){
    w_fy<-w_fy+1
    #print(paste("It is quarter",q_fy))
    qp<-get_predict_quota_prices()
    qp_names<-colnames(qp)
    annual_quota_price_holder[[w_fy]]<-qp
    annual_quota_price_holder[[w_fy]]$w_fy<-w_fy
    qp$key<-1  
}
  # Subset for the day.  Add in production coeffients and construct some extra data.
working_targeting<-copy(targeting_dataset[[day]])

#Merge the prices from qp into working_targeting
working_targeting$key<-1

working_targeting[qp, on="key", `:=`( q_americanplaiceflounder=i.q_americanplaiceflounder,
q_codGB=i.q_codGB,
q_codGOM=i.q_codGOM,
q_haddockGB=i.q_haddockGB,
q_haddockGOM=i.q_haddockGOM,
q_pollock=i.q_pollock,
q_redfish=i.q_redfish,
q_whitehake=i.q_whitehake,
q_winterflounderGB=i.q_winterflounderGB,
q_winterflounderGOM=i.q_winterflounderGOM,
q_witchflounder=i.q_witchflounder,
q_yellowtailflounderCCGOM=i.q_yellowtailflounderCCGOM,
q_yellowtailflounderGB=i.q_yellowtailflounderGB,
q_yellowtailflounderSNEMA=i.q_yellowtailflounderSNEMA)
]
working_targeting[,key:=NULL]

# Merge-update working targeting. You can also switch this to ln_obs_trawlsurvey 
working_targeting[ts,on="spstock2", `:=`(log_trawl_survey_weight=ln_trawlsurvey, 
                                         log_sector_acl=ln_sector_acl)]

working_targeting<-get_predict_eproduction(working_targeting)
working_targeting[spstock2=="nofish", harvest_sim:=0L]
working_targeting [, harvest_sim:= ifelse(is.na(dl_primary), harvest_sim, ifelse(harvest_sim >= dl_primary, dl_primary, harvest_sim))]


    # Keep or update choice_prev_fish
    working_targeting[most_recent_target, choice_prev_fish:=targeted, on=c("hullnum","spstock2")]
    working_targeting[is.na(choice_prev_fish), choice_prev_fish := 0]
     
    # working_targeting$choice_prev_fish<-working_targeting$OG_choice_prev_fish
     
    #These functions will set the catch and landings multipliers to zero depending on the value of underACL, stockarea_open, and mproc$EconType
    #zero_out_targets will set the catch and landings multipliers to zero depending on the value of underACL, stockarea_open, and mproc$EconType


    working_targeting<-joint_adjust_allocated_mults(working_targeting,fishery_holder, econtype)
    working_targeting<-joint_adjust_others(working_targeting,fishery_holder, econtype)
    working_targeting<-get_joint_production(working_targeting,spstock2s, fishery_holder, econtype) 
    # The data for MSE does not have DAS costs, so this is all commmented out.
    # adjust for DAS costs.
    # subtract off das_costs from expected and actual  revenue.
    # The _das variable is computed exactly the same as the exp_rev_total variable. 
    # If necessary the DAS and/or QUOTA costs should be set to zero either in the data  
    # working_targeting[, exp_rev_total:=exp_rev_total-das_cost]
    # working_targeting[, actual_rev_total:=actual_rev_total-das_cost]
    # Ensure revenue is 0 for the nofish
    working_targeting[spstock2=="nofish", exp_rev_total:=0L]
    working_targeting[spstock2=="nofish", actual_rev_total:=0L]
    
    #rescale to thousands of dollars.
    working_targeting[, exp_rev_total:=exp_rev_total/1000]
    working_targeting[, actual_rev_total:=actual_rev_total/1000]
    #fill the _das variables, which is needed to use the 2 and nc2 models
    working_targeting[, exp_rev_total_das:=exp_rev_total]
    working_targeting[, actual_rev_total_das:=actual_rev_total]
    
    

    
    # Predict targeting
  trips<-get_predict_etargeting(working_targeting)
    
    # Predict targeting
    # this is where infeasible trips should be eliminated.
    
    trips<-zero_out_closed_areas_asc_cutout(trips,fishery_holder,econtype)
  
  # draw trips probabilistically.  A trip is selected randomly from the choice set. 
  # The probability of selection is equal to prhat
    trips<-get_random_draw_tripsDT(trips)
  #drop out trip that did not fish (they have no landings or catch). 
    #trips<-trips[spstock2!="nofish"]

    catches<-get_reshape_catches(trips)
    landings<-get_reshape_landings(trips)
    
    #I don't think I need to do this.
    #target_rev<-get_reshape_targets_revenues(trips)
    #I don't think I need to do this.
  
  
  # update the fishery holder dataframe
  
  
  # left join landings into fishery_holder.  Replace fishery holder's cumul_catch_pounds=cumul_catch_pounds+daily_catch  remove daily_catch?  
  
  fishery_holder<-fishery_holder[catches, on="spstock2"]
  fishery_holder[, cumul_catch_pounds:= cumul_catch_pounds+daily_pounds_caught]
  fishery_holder[, daily_pounds_caught :=NULL]

  fishery_holder<-get_fishery_next_period_areaclose(fishery_holder)

  savelist<-c("id","hullnum","spstock2","doffy","exp_rev_total","exp_rev_total_das", "actual_rev_total", "gearcat","quota_cost")
  mm<-c(grep("^c_",colnames(trips), value=TRUE),grep("^l_",colnames(trips), value=TRUE),grep("^r_",colnames(trips), value=TRUE))
  savelist=c(savelist,mm)
  # Drop trips corresponding to nofish. It's just alot of zeros.
  trips<-trips[spstock2!="nofish"]
  annual_revenue_holder[[day]]<-trips[, ..savelist]
  savelist2<-c("spstock2","sectorACL","bio_model","SSB","mults_allocated", "stockarea","underACL", "stockarea_open","cumul_catch_pounds", "sectorACL_pounds")
  
  annual_fishery_status_holder[[day]]<-fishery_holder[,..savelist2]
  annual_fishery_status_holder[[day]]$doffy<-day
  # prepare the trips data.table for the next iteration
  trips<-trips[, c("spstock2","hullnum", "targeted","choice_prev_fish","OG_choice_prev_fish")]
 
  #merge in the previous value of choice_prev_fished
  trips<-merge(trips,most_recent_target, by=c("hullnum","targeted"), all=TRUE, suffixes=c("T","MRT"))
  #overwrite with the previous the target stock is no_fish
  most_recent_target<-copy(trips)
  
  
  setnames(most_recent_target,"spstock2T","spstock2", skip_absent=TRUE)
  most_recent_target[spstock2=="nofish", spstock2 :=spstock2MRT]
  most_recent_target[is.na(spstock2), spstock2 :=spstock2MRT]
  
  
  keepcols<-c("hullnum","spstock2","targeted")
  most_recent_target<-most_recent_target[, ..keepcols]
  
}
  fishery_holder[, modeled_fleet_removals_mt:=cumul_catch_pounds/(pounds_per_kg*kg_per_mt)]

  fishery_holder[, removals_mt:=modeled_fleet_removals_mt+nonsector_catch_mt]
 
#contract that list down to a single data.table
  annual_revenue_holder<-rbindlist(annual_revenue_holder) 
  annual_revenue_holder$r<-r
  annual_revenue_holder$m<-m
  annual_revenue_holder$y<-y
  annual_revenue_holder$year<-yrs[y]
  revenue_holder[[yearitercounter]]<-annual_revenue_holder
  
  #Gini for the fleet
  vessel_rev <-annual_revenue_holder %>%
    group_by(hullnum) %>%
    summarise(actual_rev=sum(actual_rev_total))
  
  Gini_fleet<-get_gini(vessel_rev,"actual_rev")
  
  vessel_rev <-annual_revenue_holder %>%
    dplyr::filter(spstock2 %in% stockNames) %>%
    group_by(hullnum) %>%
    summarise(actual_rev=sum(actual_rev_total)) 

  Gini_fleet_bioecon_stocks<-get_gini(vessel_rev,"actual_rev")
  
  
  # Total Revenue, excluding quota costs.  Better to exclude quota costs, because these are just transfers across vessels and I'm not including quota benefits anywhere.
  my_revenue_names<-grep("^r_",colnames(annual_revenue_holder) , value=TRUE)
  annual_revenue_holder2<-as.data.table(annual_revenue_holder)
  annual_revenue_holder2<-annual_revenue_holder2[, lapply(.SD, sum),.SDcols = my_revenue_names]
  total_fleet_rev<-rowSums(annual_revenue_holder2, na.rm=TRUE)
  
  #Total revenue for just the stocks with a biological model.
  my_revenue_names<-paste0("r_",stockNames)
  annual_revenue_holder2<-as.data.table(annual_revenue_holder)
  annual_revenue_holder2<-annual_revenue_holder2[, lapply(.SD, sum),.SDcols = my_revenue_names]
  total_fleet_modeled_rev<-rowSums(annual_revenue_holder2, na.rm=TRUE)

  #Total revenue for the allocated groundfish
  my_revenue_names<-paste0("r_",allocated_groundfish)
  annual_revenue_holder2<-as.data.table(annual_revenue_holder)
  annual_revenue_holder2<-annual_revenue_holder2[, lapply(.SD, sum),.SDcols = my_revenue_names]
  total_fleet_groundfish_rev<-rowSums(annual_revenue_holder2, na.rm=TRUE)
  
annual_revenue_holder2<-annual_revenue_holder2 %>%
  tidyr::pivot_longer(starts_with("r_"), names_to="spstock2", values_to="revenue")%>%
  mutate(spstock2=str_replace(spstock2,"r_",""))


#Total landings
my_landings_names<-paste0("l_",allocated_groundfish)
annual_output_price_holder<-as.data.table(annual_revenue_holder)

annual_output_price_holder<-annual_output_price_holder[, lapply(.SD, sum),.SDcols = my_landings_names]

annual_output_price_holder<-annual_output_price_holder %>%
  tidyr::pivot_longer(starts_with("l_"), names_to="spstock2", values_to="landings")%>%
  mutate(spstock2=str_replace(spstock2,"l_","")) 

#################################
## might need to fiddle with the pivot_longer, probably need to subinstr("l_" on the species)
##
#################################


# merge landings to revenues and create prices.  
# this should be a data.frame with rows that have the stock level data and columns that have landings, prices, and revenue
annual_output_price_holder<-inner_join(annual_output_price_holder, annual_revenue_holder2, by=c("spstock2")) 
annual_output_price_holder <-annual_output_price_holder %>%
  mutate(avgprice_per_lb=revenue/landings)%>%
  select(spstock2, avgprice_per_lb)


fishery_holder<-inner_join(fishery_holder,annual_output_price_holder, by="spstock2")
  
  # This is the place to do any fleet-level metrics that are sub-yearly. You can use annual_revenue_holder to to get 
  # Total rev, total rev from groundfish. revenue by species.
  # A gini or theil for total rev (across the vessels)
  # A gini or theil for the fleet's revenue sources
  
  # If you want to construct something based on removals, use "fishery_holder"  or
  # bio_output<-fishery_holder[which(fishery_holder$bio_model==1),]
  # 
  
  
  
  
  
  rm(annual_revenue_holder)
  rm(annual_output_price_holder)
  #contract the fishery-level list down to a single data.table
  annual_fishery_status_holder<- rbindlist(annual_fishery_status_holder) 
  annual_fishery_status_holder$r<-r
  annual_fishery_status_holder$m<-m
  annual_fishery_status_holder$y<-y
  annual_fishery_status_holder$year<-yrs[y]
  
  # annual_fishery_status_holder<-c(annual_fishery_status_holder,econtype)
  fishery_output_holder[[yearitercounter]]<-annual_fishery_status_holder
# We probably want to contract this down further to a data.table of "hullnum","spstock2","exp_rev_total","targeted"

  setorderv(annual_fishery_status_holder, c("spstock2","doffy"))
  annual_fishery_status_holder[,daily_pounds_caught :=cumul_catch_pounds-shift(cumul_catch_pounds,1,fill=0,type="lag"), by=spstock2]
  
  
  
  #contract the quota_price list down to a single data.table
  
  annual_quota_price_holder<-rbindlist(annual_quota_price_holder) 
  annual_quota_price_holder$r<-r
  annual_quota_price_holder$m<-m
  annual_quota_price_holder$y<-y
  annual_quota_price_holder$year<-yrs[y]
  
  fishery_quota_price_holder[[yearitercounter]]<-annual_quota_price_holder
  
  
  # Compute the within-season Gini for each modeled stock and put it in 'stock'
  for(i in 1:nstock){
      stock[[i]]$Gini_stock_within_season_BKS[y]<-get_gini_subset(dataset=annual_fishery_status_holder, y="daily_pounds_caught", filter_var="spstock2", filter_value=stock[[i]]$stockName)
  }
  
  #Gini_stock_within_season_BKS<-lapply(stockNames, get_gini_subset, dataset=annual_fishery_status_holder, y="daily_pounds_caught", filter_var="spstock2")
  #names(Gini_stock_within_season_BKS)<-stockNames
  
  
#subset fishery_holder to have just things that have a biological model. send it to a list?
bio_output<-fishery_holder[which(fishery_holder$bio_model==1),]



# Put catch (mt) into the stock list, then compute F_full
for(i in 1:nstock){
  stock[[i]]$modeled_fleet_removals_mt[y]<-bio_output$modeled_fleet_removals_mt[bio_output$stocklist_index==i]
  stock[[i]]$econCW[y]<-bio_output$removals_mt[bio_output$stocklist_index==i]
  stock[[i]]$avgprice_per_lb[y]<-bio_output$avgprice_per_lb[bio_output$stocklist_index==i]
  
    stock[[i]]<-within(stock[[i]], {
    F_full[y]<- get_F(x=econCW[y],
                      Nv=J1N[y,],
                      slxCv=slxC[y,],
                      M=natM[y],
                      waav=waa[y,])
  }) 
}




