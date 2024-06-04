#This takes care of within-year counters and indexing. These are needed/useful for the economic model.

yearitercounter<-yearitercounter+1
ebd<-random_sim_draw[replicate==r &sim_year_idx==y]
chunk_flag<-yearitercounter %% savechunksize

econ_base_draw<-ebd[,join_econbase_yr]
econ_base_idx_draw<-ebd[,join_econbase_idx]
econ_outputprice_idx_draw<-ebd[,join_outputprice_idx]
econ_mult_idx_draw<-ebd[,join_mult_idx]
econ_inputprice_idx_draw<-ebd[,join_inputprice_idx]

econ_quarterlyprice_idx_draw<-ebd[,join_quarterly_price_idx]
