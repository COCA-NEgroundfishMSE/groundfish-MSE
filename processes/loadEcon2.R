# Read in Economic Production Data. "full_targeting...", "counterfactual..." or "validation..."  is large, so it makes sense to read in each econ_year as needed.

econdatafile<-paste0(econ_data_stub,econ_base_draw,".Rds")
targeting_dataset<-readRDS(file.path(econdatapath,econdatafile))

# wm<-multipliers[[econ_mult_idx_draw]]
# if ('gffishingyear' %in% colnames(wm)){
#   wm[, gffishingyear:=NULL]
# }
#wo<-outputprices[[econ_outputprice_idx_draw]]
#if ('gffishingyear' %in% colnames(wo)){
#  wo[, gffishingyear:=NULL]
#}
#wi<-inputprices[[econ_inputprice_idx_draw]]
#if ('gffishingyear' %in% colnames(wi)){
#  wi[, gffishingyear:=NULL]
#}

quarterly_prices<-quarterly_output_prices[[econ_quarterlyprice_idx_draw]]
if ('gffishingyear' %in% colnames(quarterly_prices)){
  quarterly_prices[, gffishingyear:=NULL]
}


prices<-do.call(rbind, targeting_dataset)

keep_cols<-c("MONTH","doffy", "spstock2","gearcat",grep("^p_",colnames(prices), value=TRUE)) 

prices<-prices[, ..keep_cols]
# just keep the daily prices corresponding to one target.
prices<-prices[spstock2 %in% "codGOM",]

# pick 1 row per gear-day
prices <-prices %>%
  group_by(gearcat,doffy) %>%
  slice(1)%>%
  ungroup()

# cast the zeros to n/a and classify quarter  
prices<-prices %>%
  mutate(across(grep("^p_",colnames(prices), value=TRUE), ~ na_if(.x,0))) %>%
  mutate(q_fy = case_when(MONTH >= 5  & MONTH <= 7 ~ 1,
                          MONTH >= 8  & MONTH <= 10 ~ 2,
                          MONTH >= 11  | MONTH <= 1 ~ 3,
                          MONTH >= 2 & MONTH <= 4 ~ 4))   
prices<-prices %>%
  group_by(q_fy)%>%
  summarise(across(grep("^p_",colnames(prices), value=TRUE), \(x) mean(x, na.rm = TRUE)))

#Reshape to long format
prices<-prices %>%
  gather(spstock2, price_SFD2016,grep("^p_",colnames(prices), value=TRUE)) %>%
  mutate(spstock2=str_replace(spstock2,"p_",""))

# Join to the quarterly prices dataset
quarterly_prices <-quarterly_prices %>%
  dplyr::left_join(prices, by=join_by(q_fy,spstock2))%>%
  rename(live_priceGDP_bak=live_priceGDP)

# update the live prices with the (normalized) ones from the targeting dataset. 
quarterly_prices <-quarterly_prices %>%
  mutate(live_priceGDP=price_SFD2016/fGDPtoSFD)

quarterly_prices$live_priceGDP <- ifelse(is.na(quarterly_prices$live_priceGDP), quarterly_prices$live_priceGDP_bak, quarterly_prices$live_priceGDP)
quarterly_prices<-quarterly_prices %>%
  select(-c(price_SFD2016, live_priceGDP_bak))


#temp for debugging
#targeting_dataset$prhat<-targeting_dataset$pr

#This would be a good place to adjust any indep variables in the targeting_dataset. (like forcing the fy dummy to a different value 


#Initialize the state_dependence table  targeting
#state_dependence_file<-paste0(econ_data_stub,econ_base_draw,".Rds")

#most_recent_target<-readRDS(file.path(econdatapath,econdatafile))




