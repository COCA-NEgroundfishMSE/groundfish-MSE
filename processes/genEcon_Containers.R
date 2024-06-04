# Set up a container array that contains:
# year, nomyear  
# row of mproc
# Gross Revenues
# Other Fleet-level performance metrics 



  #yxage = matrix(NA, nrow=nyear, ncol=stockPar$nage)
  yx0 = rep(as.numeric(NA), nyear)
  est = matrix(as.numeric(NA),nyear,54)
  
  nmproc = nrow(mproc)
  
  # a placeholder to store 'yearly' results 
  save_vector_ann = array(data = as.numeric(NA),
                          dim = c(nrep, nmproc, nyear),
                          dimnames = list(paste0('rep', 1:nrep), 
                                          paste0('mproc', 1:nmproc),
                                          paste0('nyear', 1:nyear)))
  

  # A place to store 'replicate' level results (probably not using this)
  save_vector_replicate = array(data = as.numeric(NA),
                                dim = c(nrep, nmproc),
                                dimnames = list(paste0('rep', 1:nrep), 
                                                paste0('mproc', 1:nmproc)))

  yearvec<- 1:nyear
  mproc_vec <- 1:nrow(mproc)
  
  simlevelresults <- list(
    HHI_fleet = save_vector_ann,
    Shannon_fleet = save_vector_ann,
    Gini_fleet = save_vector_ann,
    Gini_fleet_bioecon_stocks = save_vector_ann,
    #Gini_stock_within_season_BKS= save_vector_ann
    total_fleet_rev=save_vector_ann,
    total_fleet_modeled_rev=save_vector_ann,
    total_fleet_groundfish_rev=save_vector_ann,
    Theil_managed_CtoB = save_vector_ann,
    Theil_managed_Relative_C=save_vector_ann
    )

 rm(list=c("save_vector_replicate", "save_vector_ann", "yx0", "yearvec", "mproc_vec","est","nmproc"))
