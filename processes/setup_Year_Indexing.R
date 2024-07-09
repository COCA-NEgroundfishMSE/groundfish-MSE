# Code to assign years of economic data based on mproc$econ_year_style[m].  This code runs 1 time every time runSim.R is run, so it is not particuarly important to optimize for speed
# So far, there are 4 options:
# 1. Randomly select a year  - each year of the MSE gets randomly matched with a year of economic data. This is done with replacement.
# 2. BlockRandom.  each year of the MSE gets randomly matched with a year of economic data. Each replicate will have the same economic year.
    # In Rep 1, if cal_year=2011 matches to econ_year=2012, then in Rep 2, cal_year=2011 will match to econ_year=2012.
# 3. Align - We align the 2010 economic data to the 2010 year of the simulation. We align 2011 economic data to the 2011 year of the simulation.  Once we run out of years of economic data, we start over at 2010.   
# 4. A single year 


constant_year<-suppressWarnings(as.numeric(mproc$econ_year_style[m]))

# Error check econ_year_style
econ_year_error<-1
if (mproc$econ_year_style[m] %in% c("Random", "BlockRandom","Align")){
  econ_year_error<-0 
} else if(is.na(constant_year)==FALSE){
    if(constant_year>=econ_data_start & constant_year<=econ_data_end){
      econ_year_error<-0 
  }
}

  
if (econ_year_error==1){
  stop("econ_year_style specified in mproc not recognized.")
}



# Common to all methods: 
# How many years are in the MSE and how many years of economic data are there? 
eyears<-nyear-fyear+1
num_eyears<-econ_data_end-econ_data_start+1


# Setup the table. rename the value to cal_year.  Add columns that contain the simulation's year index (indexed to the start of the yrs vector)
# and the management year index (=1 for the first year of management). Retain rows that are in the MSE timespan.
# Note, at this point the random_sim_draw dataframe has length nyear-fyear+1

random_sim_draw<-as_tibble(yrs) %>%
  rename(cal_year=value) %>%
  mutate(sim_year_idx=row_number(),
         manage_year_idx=cal_year-fmyear+1) %>%
  dplyr::filter(sim_year_idx >=fyear & sim_year_idx<=nyear)# %>%


# Handle the "Constant, BlockRandom, and Align" versions
# Blocked is done before the "expansion"
if(is.na(constant_year)==FALSE){
  # Constant year. If the column in mproc is a numeric, then put that into the matching dataframe.
  random_sim_draw<-cbind(random_sim_draw, constant_year)
  names(random_sim_draw)[length(names(random_sim_draw))]<-"join_econbase_yr" 
} else if (mproc$econ_year_style[m]=="BlockRandom"){
  # Randomly draw an economic year and cbind it to the random_sim_draw dataframe
  join_econbase_yr=sample(econ_data_start:econ_data_end, size=nrow(random_sim_draw),replace=TRUE)
  random_sim_draw<-cbind(random_sim_draw, join_econbase_yr)
}  else  if (mproc$econ_year_style[m]=="Align"){
  # This is some pretty weird code, but it seems to work.
  # Align so that cal_year==econ_data_start <--> join_econbase_yr==econ_data_start
  # Look up how far offset things are
  # This will break if the econ_data is not somewhere "within the simulation duration" 
  if(econ_data_start<=2010 & econ_data_end>=2010){
    offset<-random_sim_draw %>%
      dplyr::filter(cal_year==econ_data_start) %>%
      mutate(off=sim_year_idx %%num_eyears)
    offset<-offset$off
    
    #Create a longer sequence and subset
    join_econbase_yr <-rep(econ_data_start:econ_data_end, length.out=nrow(random_sim_draw)+offset)
    join_econbase_yr<-tail(join_econbase_yr, -1*offset)
    
    #cbind and cleanup
    random_sim_draw<-cbind(random_sim_draw, join_econbase_yr)
  } else {
    stop('Economic base data does not contain 2010. Economic data not aligned to cal_year')
  }
}

#Expand to the same number of rows as we have years*nrep. Arrange.
random_sim_draw<-random_sim_draw %>%
  slice(rep(1:n(), each=nrep)) %>%
  group_by(cal_year,sim_year_idx,manage_year_idx) %>%
  mutate(replicate=row_number()) %>%
  ungroup() %>%
  relocate(replicate) %>%
  arrange(replicate, cal_year)

# Random must be done after the "expansion"
if (mproc$econ_year_style[m]=="Random"){
# Random Year.
  join_econbase_yr=sample(econ_data_start:econ_data_end, size=nrow(random_sim_draw),replace=TRUE)
  random_sim_draw<-cbind(random_sim_draw, join_econbase_yr)
}

#  We use the join_econ_yr, join_econ_idx, join_outputprice, join_inputpprice, join_mult columns to pull in economic data. Right now, it's identical to the calendar year and manage_year_idx, but it may be advantageous to "cross" or "randomly" cross data.   
#  set the index position
random_sim_draw<-random_sim_draw %>%
  mutate(join_econbase_idx=join_econbase_yr-econ_data_start+1) %>%
  mutate(join_outputprice_idx=join_econbase_idx,
         join_inputprice_idx=join_econbase_idx,
         join_mult_idx=join_econbase_idx,
         join_quarterly_price_idx=join_econbase_idx)
random_sim_draw<-as.data.table(random_sim_draw)
# Am I using all of these columns?
# colnames(random_sim_draw)<-c("econrd","price_gfy","other_gfy")

rm(eyears)
rm(num_eyears)






#We have prepared 10 years of economic data (2010-2019), so we need to throw an error if we are out of range for any economic data that we want to import. 

if( any(random_sim_draw$join_econbase_yr <  2010| random_sim_draw$join_econbase_yr > 2019) ) stop('Economic base data not between 2010 and 2019.  Check your parameters ')

if( any(random_sim_draw$join_outputprice_idx <  1| random_sim_draw$join_outputprice_idx > 10) ) stop('Economic output price data invalid (not between 2010 and 2019).  Check your parameters ')

if( any(random_sim_draw$join_inputprice_idx <  1| random_sim_draw$join_inputprice_idx > 10) ) stop('Economic input price data invalid (not between 2010 and 2019).  Check your parameters ')

if( any(random_sim_draw$join_mult_idx <  1| random_sim_draw$join_mult_idx > 10) ) stop('Economic multiplier data invalid (not between 2010 and 2019).  Check your parameters ')
